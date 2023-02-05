DEPENDS += "cryptsetup-native"
python do_image_veritysetup () {
    import os
    import subprocess

    deploydir = d.getVar("IMGDEPLOYDIR")
    image = "{}{}.ext4".format(
        d.getVar("IMAGE_NAME"),
        d.getVar("IMAGE_NAME_SUFFIX"),
    )
    link = "{}.ext4".format(
        d.getVar("IMAGE_LINK_NAME"),
    )

    salt = d.getVar("VERITY_SALT")

    block_size = 4096

    data_size_blocks, data_size_rest = divmod(os.stat(deploydir+"/"+image).st_size, block_size)
    data_size = (data_size_blocks + (1 if data_size_rest else 0)) * block_size

    output = subprocess.check_output([
        "veritysetup", "format",
        "--no-superblock",
        "--salt={}".format(salt),
        "--data-block-size={}".format(block_size),
        "--hash-block-size={}".format(block_size),
        "--hash-offset={}".format(data_size),
        deploydir+"/"+image, deploydir+"/"+image,
        ])
    with open(deploydir+"/"+image+".verity-info", "wb") as f:
        f.write(output)

    params = []
    for line in output.decode('ASCII').splitlines():
        if not ":" in line:
            continue
        k, v = line.split(":", 1)
        k = k.strip().upper().replace(" ", "_")
        v = v.strip()
        print(k, v)
        params.append("VERITY_{}={}".format(k, v))

    params.append("VERITY_DATA_SECTORS={}".format(data_size//512))

    with open(deploydir+"/"+image+".verity-params", "w") as f:
        f.write('\n'.join(params))

    try:
        os.remove(deploydir+"/"+link+".verity-info")
    except FileNotFoundError:
        pass
    os.symlink(image+".verity-info", deploydir+"/"+link+".verity-info")

    try:
        os.remove(deploydir+"/"+link+".verity-params")
    except FileNotFoundError:
        pass
    os.symlink(image+".verity-params", deploydir+"/"+link+".verity-params")
}
IMAGE_POSTPROCESS_COMMAND += "do_image_veritysetup;"
