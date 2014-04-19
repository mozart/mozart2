import sys

def main(filename):
    result = 'clc;\nclose all;\nclear all;\n\nn = 9;\nSpace = zeros(n,1);\nTime = zeros(n,1);\n\n'
    tmp = ''
    iS = 1
    iT = 1
    comp = 0
    for line in open(filename):
        splt = line.split(' ')
        if len(splt) < 2:
            continue
        if splt[0] == 'Testing':
            if splt[1].startswith('"Space'):
                tmp =  'Space('+str(iS)+') = '
                iS = iS + 1
            elif splt[1].startswith('"Time'):
                tmp =  'Time('+str(iT)+') = '
                iT = iT + 1
        elif splt[1] == 'comprehensions':
            comp = int(splt[3])
        elif splt[0] == '\'Equivalents':
            tmp = tmp + str(int(splt[10])*1.0/comp) + ';\n'
            result = result + tmp
    result = result + '\nfigure;\nplot([1 n],[100 100],\'g-\', 1:n,Space*100,\'r.-\', 1:n,Time*100,\'b.-\');'
    result = result + '\nlegend(\'100%\',\'Space\',\'Time\');\ntitle(\'Implementation analysis (equivalent / implementation)\');'
    result = result + '\nxlabel(\'Test number\');\nylabel(\'Implementation efficiency (%)\');'
    result = result + '\naxis([1 n 95 115]);\ngrid on;'
    return(result)

print main(sys.argv[1])
