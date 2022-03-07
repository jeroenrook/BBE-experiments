import re

def get_last_level_directory_name(filepath):
    if filepath[-1] == r'/':
        filepath = filepath[0:-1]
    right_index = filepath.rfind(r'/')
    if right_index < 0:
        pass
    else:
        filepath = filepath[right_index + 1:]
    return filepath

def build_param_string(params):
    def pairwise(lst):
        lst = iter(lst)
        return zip(lst, lst)

    paramstring = []
    for param, value in pairwise(params):
        paramstring.append(f"-{param} {value}")
    return " ".join(paramstring)

def parse_solution_set(output_list):
    measure = {"HV": None, "IGDP": None, "SP": None}
    do_match = False
    for line in output_list:
        line = line.strip()
        print(line)

        if line == "s MEASURES":
            do_match = True
        m = re.match(r"s HV ([\d\.e-]+)", line)
        if do_match and m is not None:
            measure["HV"] = float(m.group(1))
        m = re.match(r"s HVN ([\d\.e-]+)", line)
        if do_match and m is not None:
            measure["HVN"] = float(m.group(1))
        m = re.match(r"s IGDP ([\d\.e-]+)", line)
        if do_match and m is not None:
            measure["IGDP"] = float(m.group(1))
        m = re.match(r"s SP ([\d\.e-]+)", line)
        if do_match and m is not None:
            measure["SP"] = float(m.group(1))
        m = re.match(r"s SPD ([\d\.e-]+)", line)
        if do_match and m is not None:
            measure["SPD"] = float(m.group(1))

    if measure["HV"] is None:
        measure["HV"] = None
        measure["IGDP"] = 2**32-1
        measure["SP"] = 0
        measure["SPD"] = 0
    return measure