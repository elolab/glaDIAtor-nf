process InferSwathWindows {
    input:
    file diafile

    output: 
    file "swath-windows.txt"

    script:
    """
    #!/usr/bin/env python3

    import xml.etree.ElementTree as ET
    import os

    def read_swath_windows(dia_mzML):

        print ("DEBUG: reading_swath_windows: ", dia_mzML)

        context = ET.iterparse(dia_mzML, events=("start", "end"))

        windows = {}
        for event, elem in context:

            if event == "end" and elem.tag == '{http://psi.hupo.org/ms/mzml}precursor':
                il_target = None
                il_lower = None
                il_upper = None

                isolationwindow = elem.find('{http://psi.hupo.org/ms/mzml}isolationWindow')
                if isolationwindow is None:
                    raise RuntimeError("Could not find isolation window; please supply --swath_windows_file to Gladiator.")
                for cvParam in isolationwindow.findall('{http://psi.hupo.org/ms/mzml}cvParam'):
                    name = cvParam.get('name')
                    value = cvParam.get('value')

                    if (name == 'isolation window target m/z'):
                        il_target = value
                    elif (name == 'isolation window lower offset'):
                        il_lower = value
                    elif (name == 'isolation window upper offset'):
                        il_upper = value

                ionList = elem.find('{http://psi.hupo.org/ms/mzml}selectedIonList')

                selectedion = ionList.find('{http://psi.hupo.org/ms/mzml}selectedIon')

                if selectedion:

                    for cvParam in selectedion.findall('{http://psi.hupo.org/ms/mzml}cvParam'):
                        name = cvParam.get('name')
                        value = cvParam.get('value')

                        if (name == 'selected ion m/z'):
                            if not il_target:
                                il_target = value

                if not il_target in windows:
                    windows[il_target] = (il_lower, il_upper)
                else:
                    lower, upper = windows[il_target]
                    assert (il_lower == lower)
                    assert (il_upper == upper)
                    return windows

        return windows

    def create_swath_window_files(cwd, dia_mzML):
        windows = read_swath_windows(dia_mzML)
        swaths = []
        for x in windows:
            target_str = x
            lower_str, upper_str = windows[x]
            target = float(target_str)
            lower = float(lower_str)
            upper = float(upper_str)
            assert (lower > 0)
            assert (upper > 0)
            swaths.append((target - lower, target + upper))
        swaths.sort(key=lambda tup: tup[0])
        # here we use chr(10) (equivalent to slash n), and chr(9) (equivalent to slash t)  because i dont wanna deal with nextflow headaches
        newline_character = chr(10)
        tab_character = chr(9)
        with open(os.path.join(cwd, "swath-windows.txt"), "w") as fh_swaths:
            for lower,upper in swaths:
                fh_swaths.write(str(lower) + tab_character + str(upper)  + newline_character)
        return fh_swaths

    swaths = create_swath_window_files(".", "${diafile}")
    """
}
