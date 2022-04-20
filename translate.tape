
task translate_test_sets : splitters
    :: translation_model=@
    :: language_pair=@
    :: pyenv=@ :: .submitter=$grid :: devices=@
    :: devices_per_task=0
    :: .resource_flags=$gpuResourceFlags :: .action_flags=$gpuActionFlags
  < input_source_data=$out@split_test_sets
  < model_path=$model@train_split_models
  < data_path=$data@train_split_models
  > out
  {
    mkdir -p out
    SOURCE=$(echo $language_pair | cut -d'-' -f1)
    TARGET=$(echo $language_pair | cut -d'-' -f2)
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
        echo "nothing to do"
      fi
    done;
  }
