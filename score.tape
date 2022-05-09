
task score_test_sets : splitters
    :: translation_model=@
    :: test_data_path=@
    :: retain_segmentations=@
    :: language_pair=@
    :: pyenv=@ :: .submitter=$grid :: devices=@
    :: devices_per_task=0
    :: .resource_flags=$cpuResourceFlags :: .action_flags=$cpuActionFlags
  < translations=$out@translate_test_sets
  < input_source_data=$out@split_test_sets
  {
    set +euo
    source ~/.bashrc
    conda deactivate
    conda activate py3
    set -euo pipefail
    mkdir -p out
    mkdir -p doc_out
    SOURCE=$(echo $language_pair | cut -d'-' -f1)
    TARGET=$(echo $language_pair | cut -d'-' -f2)
    for f in $translations/*.$TARGET; do
      echo $f
      docid=$(echo $f | rev | cut -d'/' -f1 | cut -d'.' -f2 | rev)
      refdoc=$test_data_path/$language_pair/docs/$docid.$TARGET
      srcdoc=$input_source_data/$docid.$SOURCE
      if [[ $retain_segmentations == "true" ]]; then
        # combine
        paste $srcdoc.idx $f | combine-by-line-number.py > out/$docid.$TARGET
        cat $f | tr '\n' ' ' > doc_out/$docid.$TARGET
      else
        conda deactivate
        conda activate docaligner
        python ~/code/docaligner/project_text.py $f $refdoc --echo sys > out/$docid.$TARGET
        #python ~/code/word-based-aligner/align.py --tokens_path $f \
        #        $refdoc \
        #        --clean > out/$docid.$TARGET
        cat $f | tr '\n' ' ' > doc_out/$docid.$TARGET
      fi
      cat out/$docid.$TARGET >> hypothesis
      cat $refdoc >> reference

      cat doc_out/$docid.$TARGET >> doc_hypothesis
      cat $refdoc | tr '\n' ' ' >> doc_reference
    done;
    echo "sentence BLEU"
    cat hypothesis | sacrebleu reference -l $language_pair

    echo "document BLEU"
    cat doc_hypothesis | sacrebleu doc_reference -l $language_pair
  }

