
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


task comet_score_test_sets : splitters
  :: translation_model=@
  :: test_data_path=@
  :: retain_segmentations=@
  :: language_pair=@
  :: pyenv=@ :: .submitter=$grid :: devices=@
  :: devices_per_task=0
  :: .resource_flags=$gpuShortResourceFlags :: .action_flags=$gpuShortActionFlags
< translations=$out@translate_test_sets
< input_source_data=$out@split_test_sets
> sent doc
{
  mkdir -p out
  mkdir -p doc_out

  mkdir -p src
  mkdir -p doc_src

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
      cp $test_data_path/$language_pair/docs/$docid.$SOURCE src/$docid.$SOURCE
    else
      conda deactivate
      conda activate docaligner
      python ~/code/docaligner/project_text.py $f $refdoc --echo sys > out/$docid.$TARGET
      cat $test_data_path/$language_pair/docs/$docid.$SOURCE | tr '\n' ' ' > doc_src/$docid.$SOURCE
      cat $f | tr '\n' ' ' > doc_out/$docid.$TARGET
    fi
    cat src/$docid.$SOURCE >> source
    cat out/$docid.$TARGET >> hypothesis
    cat $refdoc >> reference

    cat doc_src/$docid.$SOURCE >> doc_source
    cat doc_out/$docid.$TARGET >> doc_hypothesis
    cat $refdoc | tr '\n' ' ' >> doc_reference
  done;
  conda deactivate
  conda activate metrics
  echo "sentence COMET"
  comet-score -s source -t hypothesis -r reference |& tee comet.sentence

  echo "document COMET"
  comet-score -s doc_source -t doc_hypothesis -r doc_reference |& tee comet.doc

  ln -s comet.sentence sent
  ln -s comet.doc doc
}
