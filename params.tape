global {
    inference_splitter=(InferenceSplitter: always-split documents ersatz ersatz-m ml-punkt moses punkt spacy-split)
    train_splitter=(TrainSplitter: always-split documents ersatz ersatz-m ml-punkt moses punkt spacy-split)
    test_data_path=(TestData: wmt20="/exp/rwicks/ersatz/exp/inference/wmt20-sgm")
    language_pair=(LanguagePair: cs-en de-en de-fr en-cs en-de en-pl en-ru fr-de pl-en ru-en)
    retain_segmentations=(Retain: true false)
    translation_model=(TranslationModel: prism always-split documents ersatz ersatz-m ml-punkt moses punkt spacy-split)
    aligner=(Aligner: vecalign global)
    reverse=(Reverse: false true)
    train_data_path="/exp/rwicks/ersatz/data/inference"
    dev_data_path="/exp/rwicks/ersatz/data/inference-dev/"
    vocab_size=32000
}
