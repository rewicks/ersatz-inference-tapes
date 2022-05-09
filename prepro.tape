task align_train_data : splitters
  :: train_data_path=@
  :: language_pair=@
  :: translation_model=@
  :: aligner=@
  :: pyenv=@ :: .submitter=$grid :: devices=@
  :: devices_per_task=0
  :: .resource_flags=$gpuLowResourceFlags :: .action_flags=$gpuLowActionFlags
  < model=$model@train_subword_vocab
  < train_data_dir=$out@split_train_sets
  > src trg
  {
    if [[ $translation_model != "prism" ]]; then
        export LASER=$(realpath ~/code/LASER)
        export VECALIGN=$(realpath ~/code/vecalign)

        mkdir -p overlap
        mkdir -p embeds
        mkdir -p alignments

        SOURCE=$(echo $language_pair | cut -d'-' -f1)
        TARGET=$(echo $language_pair | cut -d'-' -f2)

        conda deactivate
        conda activate vecalign

        for f in $train_data_dir/*/*.$SOURCE; do
          echo "Working on : $f"

          src=$f
          trg="${src::-2}$TARGET"

          cat $src >> src_in
          cat $trg >> trg_in

        done;


        if [[ $aligner == "vecalign" ]]; then

            $VECALIGN/overlap.py -i src_in -o overlap/src_in -n 6
            $VECALIGN/overlap.py -i trg_in -o overlap/trg_in -n 6
            
            bash ~/code/LASER/tasks/embed/embed.sh overlap/src_in $SOURCE embeds/src_out
            bash ~/code/LASER/tasks/embed/embed.sh overlap/trg_in $TARGET embeds/trg_out

            $VECALIGN/vecalign.py --alignment_max_size 4 --src src_in --tgt trg_in \
               --src_embed overlap/src_in embeds/src_out \
               --tgt_embed overlap/trg_in embeds/trg_out > alignments/$SOURCE-$TARGET.lines

            python /exp/rwicks/ersatz/exp/inference/make-aligned.py src_in trg_in alignments/$SOURCE-$TARGET.lines alignments/$SOURCE-$TARGET

            conda deactivate
            conda activate py3

            cat alignments/*.src | spm_encode --model $model >> src
            cat alignments/*.tgt | spm_encode --model $model >> trg
        else
            bash ~/code/LASER/tasks/embed/embed.sh src_in $SOURCE embeds/src_out
            bash ~/code/LASER/tasks/embed/embed.sh trg_in $TARGET embeds/trg_out

            python ~/code/LASER/source/mine_bitexts.py --mode mine --gpu \
                --src-embeddings embeds/src_out \
                --src-lang $SOURCE \
                --trg-embeddings embeds/trg_out \
                --trg-lang $TARGET \
                --output alignments/$SOURCE-$TARGET \
                src_in trg_in

            conda deactivate
            conda activate py3

            cat alignments/$SOURCE-$TARGET | cut -f2 | spm_encode --model $model >> src
            cat alignments/$SOURCE-$TARGET | cut -f3 | spm_encode --model $model >> trg

        fi
        rm embeds/*
    else
        touch src
        touch trg
    fi

  }
