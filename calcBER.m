% Tim Smith - ENGI9867 Final Project
% Calculates the BER of a series of two-bit classifications

function ber = calcBER(YPred,YTest)
    bit_errors = 0;

    for i = 1:size(YPred,1)
        if YPred(i) ~= YTest(i)
            if YPred(i) == categorical(0)
                if YTest(i) == categorical(1) || YTest(i) == categorical(2)
                    bit_errors = bit_errors + 1;
                else
                    bit_errors = bit_errors + 2;
                end
            elseif YPred(i) == categorical(1)
                if YTest(i) == categorical(0) || YTest(i) == categorical(3)
                        bit_errors = bit_errors + 1;
                else
                    bit_errors = bit_errors + 2;
                end
            elseif YPred(i) == categorical(2)
                if YTest(i) == categorical(0) || YTest(i) == categorical(3)
                    bit_errors = bit_errors + 1;
                else
                    bit_errors = bit_errors + 2;
                end
            else
                if YTest(i) == categorical(1) || YTest(i) == categorical(2)
                    bit_errors = bit_errors + 1;
                else
                    bit_errors = bit_errors + 2;
                end
            end
        end
    end

    ber = bit_errors/(2*size(YPred,1));
end