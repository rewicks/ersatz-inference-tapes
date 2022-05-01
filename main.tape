import "submitters.tape"
import "versioners.tape"

global {
    pyenv="conda:splitter"
    ducttape_experimental_packages=true
    ducttape_experimental_submitters=true
    ducttape_experimental_imports=true
    ducttape_experimental_multiproc=true
    devices="0,1,2,3,4,5,6,7"
}

import "env_coe.tape"
import "params.tape"
import "splitting.tape"
import "train.tape"
import "translate.tape"
import "score.tape"
import "prepro.tape"

plan do_split_test_sets {
  reach split_test_sets via (InferenceSplitter: ersatz spacy-split always-split) *
        (TestData: wmt20) *
        (LanguagePair: *) *
        (Retain: *)
}

plan do_translate_test_sets {
    reach score_test_sets via (TranslationModel: prism) *
        (InferenceSplitter: *) *
        (TestData: wmt20) *
        (LanguagePair: cs-en de-en de-fr en-cs en-de en-pl en-ru en-zh fr-de pl-en ru-en zh-en) *
        (Retain: *)
}


plan do_align {
    reach align_train_data via (LanguagePair: de-en cs-en) *
        (TrainSplitter: ersatz) *
        (Aligner: vecalign)
}

plan do_score_prism {
    reach score_test_sets via (LanguagePair: *) *
        (InferenceSplitter: *) *
        (Retain: *)
}

plan do_score_trained {
    reach score_test_sets via (LanguagePair: de-en cs-en) *
        ()
}
