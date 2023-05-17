import shutil

for i in range(50):

    if i < 10:
        old_filename = f"line_myclone50_" + "0" + str(i) + ".pl"
        new_filename = f"star_myclone50_" + "0" + str(i) + ".pl"
        shutil.copy(old_filename, new_filename)
    else:
        old_filename = f"line_myclone50_{i}.pl"
        new_filename = f"star_myclone50_{i}.pl"
        shutil.copy(old_filename, new_filename)
