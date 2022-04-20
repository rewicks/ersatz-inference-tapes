task align_train_data : splitters
  :: train_data_path=@
  :: language_pair=@
  :: aligner=@
  :: pyenv=@ :: .submitter=$grid :: devices=@
  :: devices_per_task=0
  :: .resource_flags=$gpuLowResourceFlags :: .action_flags=$gpuLowActionFlags
  < model=$model@train_subword_vocab
  < train_data_dir=$out@split_train_sets
  > src trg
  {
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
      
      prefix=$(echo $f | rev | cut -d'/' -f2 | rev)

      src_out=$(echo $src | rev | cut -d'/' -f1 | rev)
      trg_out=$(echo $trg | rev | cut -d'/' -f1 | rev)

      if [[ $aligner == "vecalign" ]]; then
          $VECALIGN/overlap.py -i $src -o overlap/$src_out -n 10
          $VECALIGN/overlap.py -i $trg -o overlap/$trg_out -n 10

          bash ~/code/LASER/tasks/embed/embed.sh overlap/$src_out $SOURCE embeds/$src_out
          bash ~/code/LASER/tasks/embed/embed.sh overlap/$trg_out $TARGET embeds/$trg_out

          $VECALIGN/vecalign.py --alignment_max_size 8 --src $src --tgt $trg \
             --src_embed overlap/$src_out embeds/$src_out \
             --tgt_embed overlap/$trg_out embeds/$trg_out > alignments/$prefix.$src_out-$TARGET.lines

          rm embeds/$src_out
          rm embeds/$trg_out

          python /exp/rwicks/ersatz/exp/inference/make-aligned.py $src $trg alignments/$prefix.$src_out-$TARGET.lines alignments/$prefix.$src_out-$TARGET

      else
          cat $src >> src_in
          cat $trg >> trg_in
      fi

    done;

    if [[ $aligner == "vecalign" ]]; then
        conda deactivate
        conda activate py3

        cat alignments/*.src | spm_encode --model $model >> src
        cat alignments/*.trg | spm_encode --model $model >> trg
    else
        bash ~/code/LASER/tasks/embed/embed.sh src_in $SOURCE embeds/src_out
        bash ~/code/LASER/tasks/embed/embed.sh trg_in $TARGET embeds/trg_out

        python ~/code/LASER/source/mine_bitexts.py --mode mine --gpu \
            --src-embeddings embeds/$src_out \
            --src-lang $SOURCE \
            --trg-embeddings embeds/$trg_out \
            --trg-lang $TARGET \
            --output alignments/src_out-$TARGET \
            src_in trg_in

        cat alignments/src_out-$TARGET | cut -f1 | spm_encode --model $model >> src
        cat alignments/src_out-$TARGET | cut -f2 | spm_encode --model $model >> trg 

    fi

  }
