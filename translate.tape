
task translate_test_sets : splitters
    :: translation_model=@
    :: language_pair=@
    :: reverse=@
    :: pyenv=@ :: .submitter=$grid :: devices=@
    :: devices_per_task=0
    :: .resource_flags=$gpuResourceFlags :: .action_flags=$gpuActionFlags
  < input_source_data=$out@split_test_sets
  < model_path=$model@train_split_models
  < data_path=$data@train_split_models
  < vocab_model=$model@train_subword_vocab
  > out
  {
    mkdir -p out
    if [[ $reverse == "true" ]]; then
        SOURCE=$(echo $language_pair | cut -d'-' -f2)
        TARGET=$(echo $language_pair | cut -d'-' -f1)
    else
        SOURCE=$(echo $language_pair | cut -d'-' -f1)
        TARGET=$(echo $language_pair | cut -d'-' -f2)
    fi

    for f in $input_source_data/*.sent; do
      echo $f
      outfile=$(echo $f | rev | cut -d'/' -f1 | rev | cut -d'.' -f1)
      outfile=out/$outfile.$TARGET
      if [[ $translation_model == "prism" ]]; then
            # path to directory containing 'dict.src.txt' and 'checkpoint.pt'
            modeldir=/home/hltcoe/mpost/models/prism_private/m39v1
            scriptdir=/home/hltcoe/rwicks/scripts/prism

            module load cuda11.0/toolkit cudnn
            source /opt/anaconda3/etc/profile.d/conda.sh

            nvidia-smi
            hostname
            env

            echo "Calling bash $scriptdir/translate.sh $f $TARGET $outfile $@"

            bash $scriptdir/translate.sh $f $TARGET $outfile "$@"
      else
        fairseq-interactive --path=$model_path \
            $data_path \
            --input=$f \
            > $outfile.log
        grep "H-[0-9]*" $outfile.log | cut -f3 -d$'\t' | tr -d ' ' | sed 's/▁/ /g' | perl -pe 's/^\s+//' > $outfile
      fi
    done;
  }
