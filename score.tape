
task score_test_sets : splitters
    :: translation_model=@
    :: test_data_path=@
    :: retain_segmentations=@
    :: reverse=@
    :: language_pair=@
    :: pyenv=@ :: .submitter=$grid :: devices=@
    :: devices_per_task=0
    :: .resource_flags=$cpuResourceFlags :: .action_flags=$cpuActionFlags
  < translations=$out@translate_test_sets
  < input_source_data=$out@split_test_sets
  {
    mkdir -p out
    mkdir -p doc_out
    mkdir -p w_out
    mkdir -p w_doc_out

    if [[ $reverse == "true" ]]; then
        SOURCE=$(echo $language_pair | cut -d'-' -f2)
        TARGET=$(echo $language_pair | cut -d'-' -f1)
    else
        SOURCE=$(echo $language_pair | cut -d'-' -f1)
        TARGET=$(echo $language_pair | cut -d'-' -f2)
    fi
    for f in $translations/*.$TARGET; do
      echo $f
      docid=$(echo $f | rev | cut -d'/' -f1 | cut -d'.' -f2 | rev)
      refdoc=$test_data_path/$language_pair/docs/$docid.$TARGET
      srcdoc=$input_source_data/$docid.$SOURCE
      if [[ $retain_segmentations == "true" ]]; then
        # combine
        paste $srcdoc.idx $f | combine-by-line-number.py > out/$docid.$TARGET
        cat $f | tr '\n' ' ' > doc_out/$docid.$TARGET
        
        paste $srcdoc.idx $f | combine-by-line-number.py > w_out/$docid.$TARGET
        cat $f | tr '\n' ' ' > w_doc_out/$docid.$TARGET
      else
        conda deactivate
        conda activate docaligner
        python ~/code/docaligner/project_text.py $f $refdoc --echo sys > out/$docid.$TARGET
        
        conda deactivate
        conda activate py3
        python ~/code/word-based-aligner/align.py --tokens_path $f $refdoc --clean > w_out/$docid.$TARGET
    
        cat $f | tr '\n' ' ' > doc_out/$docid.$TARGET
        cat $f | tr '\n' ' ' > w_doc_out/$docid.$TARGET
      fi
      cat out/$docid.$TARGET >> hypothesis
      cat $refdoc >> reference

      cat doc_out/$docid.$TARGET >> doc_hypothesis
      cat $refdoc | tr '\n' ' ' >> doc_reference

      echo "" >> doc_hypothesis
      echo "" >> doc_reference
      
      cat w_out/$docid.$TARGET >> w_hypothesis
      cat $refdoc >> w_reference

      cat w_doc_out/$docid.$TARGET >> w_doc_hypothesis
      cat $refdoc | tr '\n' ' ' >> w_doc_reference

      echo "" >> w_doc_hypothesis
      echo "" >> w_doc_reference

    done;
    conda deactivate
    conda activate py3
    echo "sentence BLEU"
    cat hypothesis | sacrebleu reference -l $language_pair

    echo "document BLEU"
    cat doc_hypothesis | sacrebleu doc_reference -l $language_pair
    
    echo "word based aligner sentence BLEU"
    cat w_hypothesis | sacrebleu w_reference -l $language_pair
    
    echo "word based aligner document BLEU"
    cat w_doc_hypothesis | sacrebleu w_doc_reference -l $language_pair

  }


task comet_score_test_sets : splitters
  :: translation_model=@
  :: test_data_path=@
  :: retain_segmentations=@
  :: language_pair=@
  :: pyenv=@ :: .submitter=$grid :: devices=@
  :: devices_per_task=0
  :: .resource_flags=$gpuResourceFlags :: .action_flags=$gpuActionFlags
< translations=$out@translate_test_sets
< input_source_data=$out@split_test_sets
> sent doc
{
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
      cat $f | tr '\n' ' ' > doc_out/$docid.$TARGET
    fi
  
    cat $test_data_path/$language_pair/docs/$docid.$SOURCE >> source
    cat out/$docid.$TARGET >> hypothesis
    cat $refdoc >> reference

    cat $test_data_path/$language_pair/docs/$docid.$SOURCE | tr '\n' ' ' >> doc_source
    cat doc_out/$docid.$TARGET >> doc_hypothesis
    cat $refdoc | tr '\n' ' ' >> doc_reference

    echo "" >> doc_source
    echo "" >> doc_hypothesis
    echo "" >> doc_reference
    
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
