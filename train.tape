
task train_split_models : splitters
    :: language_pair=@
    :: translation_model=@
    :: pyenv=@ :: .submitter=$grid :: devices=@
    :: devices_per_task=0
    :: .resource_flags=$cpuResourceFlags :: .action_flags=$cpuActionFlags
  > model data
  {
    mkdir -p out
    SOURCE=$(echo $language_pair | cut -d'-' -f1)
    TARGET=$(echo $language_pair | cut -d'-' -f2)
    if [[ $translation_model == "prism" ]]; then
      touch model
      touch data
    else 
      touch model 
      touch data
    fi

  }

task train_subword_vocab : splitters
  :: train_data_path=@
  :: language_pair=@
  :: vocab_size=@
  :: pyenv=@ :: .submitter=$grid :: devices=@
  :: devices_per_task=0
  :: .resource_flags=$cpuResourceFlags :: .action_flags=$cpuActionFlags
  > vocab model
  {
    conda deactivate
    conda activate py3

    for f in $train_data_path/$language_pair/*/*; do
      cat $f >> data
    done;

    spm_train --input data \
      --model_prefix out \
      --vocab_size=$vocab_size

    rm data

    ln -s out.model model
    ln -s out.vocab vocab

  }
