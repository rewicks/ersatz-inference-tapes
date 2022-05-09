task split_test_sets : splitters
    :: test_data_path=@
    :: language_pair=@
    :: inference_splitter=@
    :: retain_segmentations=@
    :: pyenv=@ :: .submitter=$grid :: devices=@
    :: devices_per_task=0
    :: .resource_flags=$cpuResourceFlags :: .action_flags=$cpuActionFlags
  > out
  {
    which python
    mkdir -p out
    DATA_PATH="$test_data_path/$language_pair/docs"
    SOURCE=$(echo $language_pair | cut -d'-' -f1)
    TARGET=$(echo $language_pair | cut -d'-' -f2)
    if [[ $retain_segmentations == "true" ]]; then
        for f in $DATA_PATH/*; do
          echo $f
          lang=$(echo $f | rev | cut -d'.' -f1 | rev)
          outfile=$(echo $f | rev | cut -d'/' -f1 | rev)
          outfile=out/$outfile
          if [[ $lang == $SOURCE ]]; then
            if [[ $inference_splitter == "ersatz" ]]; then
              cat $f | add_punc.py | awk '{print NR"\t"$0}' | ersatz -C 1 > $outfile
              cut -f1 $outfile > $outfile.idx
              cut -f2 $outfile > $outfile.sent
            else
              if [[ $inference_splitter == "ersatz-m" ]]; then
                cat $f | add_punc.py | awk '{print NR"\t"$0}' | ersatz -C 1 --model $SOURCE > $outfile
                cut -f1 $outfile > $outfile.idx
                cut -f2 $outfile > $outfile.sent
              else
                if [[ $inference_splitter == "documents" ]]; then
                  cat $f | add_punc.py | awk '{print NR"\t"$0}' > $outfile
                  cut -f1 $outfile > $outfile.idx
                  cut -f2 $outfile > $outfile.sent
                else
                  cat $f | add_punc.py | awk '{print NR"\t"$0}' | $inference_splitter --text_ids 1 --lang $SOURCE > $outfile
                  cut -f1 $outfile > $outfile.idx
                  cut -f2 $outfile > $outfile.sent
                fi
              fi
            fi
          fi
        done;
    else
        for f in $DATA_PATH/*; do
          echo $f
          lang=$(echo $f | rev | cut -d'.' -f1 | rev)
          outfile=$(echo $f | rev | cut -d'/' -f1 | rev)
          outfile=out/$outfile
          if [[ $lang == $SOURCE ]]; then
            if [[ $inference_splitter == "ersatz" ]]; then
              cat $f | add_punc.py | tr '\n' ' ' | ersatz > $outfile.sent
            else
              if [[ $inference_splitter == "ersatz-m" ]]; then
                cat $f | add_punc.py | tr '\n' ' ' | ersatz --model $SOURCE > $outfile.sent
              else
                if [[ $inference_splitter == "documents" ]]; then
                  cat $f | add_punc.py > $outfile.sent
                else
                  cat $f | add_punc.py | tr '\n' ' ' | $inference_splitter --lang $SOURCE > $outfile.sent
                fi
              fi
            fi
          fi
        done;
    fi
  }

task split_train_sets : splitters
    :: train_data_path=@
    :: language_pair=@
    :: translation_model=@
    :: pyenv=@ :: .submitter=$grid :: devices=@
    :: devices_per_task=0
    :: .resource_flags=$cpuResourceFlags :: .action_flags=$cpuActionFlags
    > out
    {
        mkdir -p out
        if [[ $translation_model != "prism" ]]; then
            for f in $train_data_path/$language_pair/*/*; do
                LANG=$(echo $f | rev | cut -d'.' -f1 | rev)
                PARENT_DIR=$(echo $f | rev | cut -d'/' -f2 | rev)
                mkdir -p out/$PARENT_DIR
                DOCID=$(echo $f | rev | cut -d'/' -f1 | rev)
                OUTFILE=out/$PARENT_DIR/$DOCID
                if [[ $translation_model == "ersatz" ]]; then
                    cat $f | add_punc.py | tr '\n' ' ' | ersatz > $OUTFILE
                else
                    if [[ $translation_model == "ersatz-m" ]]; then
                        cat $f | add_punc.py | tr '\n' ' ' | ersatz --model $LANG > $OUTFILE
                    else
                        if [[ $translation_model == "documents" ]]; then
                            cp $f $OUTFILE
                        else
                            cat $f | add_punc.py | tr '\n' ' ' | $translation_model --lang $LANG > $OUTFILE
                        fi
                    fi
               fi
            done;
        else
            mkdir -p out/prefix/
            SOURCE=$(echo $language_pair | cut -d'-' -f1)
            TARGET=$(echo $language_pair | cut -d'-' -f2)
            echo "This is a filler sentence" > out/prefix/prefix.$SOURCE
            echo "This is also a filler sentence" > out/prefix/prefix.$TARGET
        fi
  }
