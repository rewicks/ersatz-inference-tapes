
task train_split_models : splitters
    :: language_pair=@
    :: translation_model=@
    :: dev_data_path=@
    :: reverse=@
    :: pyenv=@ :: .submitter=$grid :: devices=@
    :: devices_per_task=0
    :: .resource_flags=$gpuResourceFlags :: .action_flags=$gpuActionFlags
  > model data
  < src_data=$src@align_train_data
  < trg_data=$trg@align_train_data
  < vocab_model=$model@train_subword_vocab
  {
    mkdir -p out
    mkdir -p raw_data
    mkdir -p data

    if [[ $reverse == "true" ]]; then
        SOURCE=$(echo $language_pair | cut -d'-' -f2)
        TARGET=$(echo $language_pair | cut -d'-' -f1)
    else
        SOURCE=$(echo $language_pair | cut -d'-' -f1)
        TARGET=$(echo $language_pair | cut -d'-' -f2)
    fi

    if [[ $translation_model == "prism" ]]; then
        touch model
        touch data
    else

        conda deactivate
        conda activate py3
        cat $dev_data_path/$language_pair/*.$SOURCE | spm_encode --model $vocab_model >> raw_data/dev.$SOURCE
        cat $dev_data_path/$language_pair/*.$TARGET | spm_encode --model $vocab_model >> raw_data/dev.$TARGET

        if [[ $reverse == "true" ]]; then
            cp $trg_data raw_data/train.$SOURCE
            cp $src_data raw_data/train.$TARGET
        else
            cp $src_data raw_data/train.$SOURCE
            cp $trg_data raw_data/train.$TARGET
        fi

        # Trains a fairseq model.
        conda deactivate
        conda activate fairseq

        printf -v DATE '%(%Y-%m-%d-%H-%M-%S)T' -1
        echo $DATE

        fairseq-preprocess \
            --source-lang $SOURCE \
            --target-lang $TARGET \
            --trainpref raw_data/train \
            --validpref raw_data/dev \
            --workers 30 \
            --destdir data/ \
            --seed 1337

        fairseq-train data/ \
          --fp16 \
          --memory-efficient-fp16 \
          --num-workers 0 \
          --source-lang $SOURCE \
          --target-lang $TARGET \
          --save-dir out \
          --seed 2 \
          --arch transformer \
          --encoder-layers 6 \
          --decoder-layers 6 \
          --encoder-embed-dim 512 \
          --decoder-embed-dim 512 \
          --encoder-ffn-embed-dim 2048 \
          --decoder-ffn-embed-dim 2048 \
          --encoder-attention-heads 8 \
          --decoder-attention-heads 8 \
          --share-decoder-input-output-embed \
          --dropout 0.1 \
          --attention-dropout 0.1 \
          --relu-dropout 0.1 \
          --weight-decay 0.0 \
          --criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
          --optimizer adam --adam-betas '(0.9, 0.98)' \
          --clip-norm 2.0 \
          --lr-scheduler inverse_sqrt \
          --warmup-updates 3000 \
          --warmup-init-lr 1e-7 --lr 0.0005 --min-lr 1e-9 \
          --max-tokens 16000 \
          --max-epoch 100 \
          --update-freq 1 \
          --patience 10 \
          --ddp-backend=no_c10d \
          --no-last-checkpoints \
          --no-epoch-checkpoints \
          --log-format json --log-interval 1  > out/log.$DATE

        ln -s out/checkpoint_best.pt model
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
    if [[ $language_pair == "de-en" || $language_pair == "cs-en" ]]; then
        for f in $train_data_path/$language_pair/*/*; do
          cat $f >> data
        done;

        spm_train --input data \
          --model_prefix out \
          --vocab_size=$vocab_size

        rm data

        ln -s out.model model
        ln -s out.vocab vocab
    else
        touch model
        touch vocab
    fi

  }
