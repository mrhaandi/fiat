From Fiat.Narcissus Require Import Examples.TutorialPrelude.
Require Import Fiat.Narcissus.Automation.Error.

Record msg := { data : list (word 8) }.
Definition format :=
  format_nat 8 ◦ length ◦ data ++
  format_list format_word ◦ data.
Definition invariant (m : msg) := length (m.(data)) < pow2 9.

Definition dec : Maybe (CorrectAlignedDecoderFor invariant format).
Proof.
  maybe_synthesize_aligned_decoder.
  Show Proof.
Defined.
