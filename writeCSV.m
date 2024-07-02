% Tim Smith - ENGI9867 Final Project
% Simple function to write CSV files in a format that LaTeX likes

function writeCSV(name,x,y,normalize)
    if normalize == 1
        y = y/abs(max(y));
    end
    fileName = strcat('CSV/',name,'.csv');
    dlmwrite(fileName,['x' 'y'],'delimiter',',');
    dlmwrite(fileName,[x' y'],'delimiter',',','-append');
end