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

plan do_test_comet {
    reach comet_score_test_sets via (TranslationModel: prism) *
        (InferenceSplitter: ersatz moses) *
        (TestData: wmt20) *
        (LanguagePair: cs-en) *
        (Retain: *)
}

plan do_score_bleu_test_sets {
    reach score_test_sets via (TranslationModel: prism) *
        (InferenceSplitter: always-split documents ersatz moses punkt spacy-split) *
        (TestData: wmt20) *
        (LanguagePair: cs-en de-en de-fr en-cs en-de en-pl en-ru en-zh fr-de pl-en ru-en zh-en) *
        (Retain: *)
}

plan do_score_comet_test_sets {
    reach comet_score_test_sets via (TranslationModel: prism) *
        (InferenceSplitter: always-split documents ersatz ersatz-m ml-punkt moses punkt spacy-split) *
        (TestData: wmt20) *
        (LanguagePair: cs-en de-en en-cs en-de en-pl en-ru en-zh pl-en ru-en zh-en) *
        (Retain: *)
}

plan do_score_custom {
    reach score_test_sets via (TranslationModel: spacy-split) *
        (InferenceSplitter: always-split documents ersatz ersatz-m moses punkt spacy-split) *
        (TestData: wmt20) *
        (LanguagePair: de-en) *
        (Retain: false) *
        (Aligner: global vecalign)
}

plan do_align_train {
    reach score_test_sets via (TranslationModel: always-split documents ersatz moses punkt spacy-split pairs) *
        (InferenceSplitter: always-split documents ersatz ml-punkt moses punkt spacy-split) *
        (TestData: wmt20) *
        (LanguagePair: de-en) *
        (Retain: false) *
        (Aligner: global vecalign) *
        (Reverse: true)
}

plan do_split_train {
    reach split_train_sets via (TranslationModel: always-split documents ersatz ersatz-m moses punkt spacy-split) *
        (InferenceSplitter: always-split documents ersatz ersatz-m ml-punkt moses punkt spacy-split) *
        (TestData: wmt20) *
        (LanguagePair: cs-en) *
        (Retain: false) *
        (Aligner: global)
}

plan do_test_custom {
    reach score_test_sets via (TranslationModel: always-split) *
        (InferenceSplitter: always-split) *
        (TestData: wmt20) *
        (LanguagePair: de-en) *
        (Retain: false) *
        (Aligner: global)
}


plan do_align {
    reach align_train_data via (LanguagePair: de-en) *
        (TranslationModel: always documents ersatz ersatz-m ml-punkt moses punkt spacy-split) *
        (Aligner: vecalign global)
}

plan do_train {
    reach train_split_models via (LanguagePair: de-en) *
        (TranslationModel: always documents ersatz ersatz-m ml-punkt moses punkt spacy-split) *
        (Aligner: global) *
        (Reverse: false)
}

plan do_score_prism {
    reach score_test_sets via (LanguagePair: *) *
        (InferenceSplitter: *) *
        (Retain: *)
}

#plan do_score_trained {
#    reach score_test_sets via (LanguagePair: de-en cs-en) *
#        ()
#}
