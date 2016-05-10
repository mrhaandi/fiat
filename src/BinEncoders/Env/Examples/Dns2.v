Require Import
        Coq.Strings.String
        Coq.Vectors.Vector.

Require Import
        Fiat.Examples.DnsServer.Packet
        Fiat.Common.SumType
        Fiat.Common.BoundedLookup
        Fiat.Common.ilist
        Fiat.QueryStructure.Specification.Representation.Notations
        Fiat.QueryStructure.Specification.Representation.Heading
        Fiat.QueryStructure.Specification.Representation.Tuple
        Fiat.BinEncoders.Env.Common.Specs
        Fiat.BinEncoders.Env.Common.Compose
        Fiat.BinEncoders.Env.Automation.Solver
        Fiat.BinEncoders.Env.Lib2.Word
        Fiat.BinEncoders.Env.Lib2.Nat
        Fiat.BinEncoders.Env.Lib2.String
        Fiat.BinEncoders.Env.Lib2.FixList
        Fiat.BinEncoders.Env.Lib2.SumType
        Fiat.BinEncoders.Env.Lib2.SteppingList.

Require Import
        Bedrock.Word.

Import Coq.Vectors.VectorDef.VectorNotations.

Section DnsPacket.

  Open Scope Tuple_scope.

  Variable bin : Type.

  Variable cache : Cache.
  Variable cacheAddNat : CacheAdd cache nat.

  Variable transformer : Transformer bin.
  Variable transformerUnit : TransformerUnit transformer bool.

  Notation encoder x := (x ->  CacheEncode -> bin * CacheEncode).
  Notation decoder x := (bin -> CacheDecode -> x * bin * CacheDecode).
  Variable encode_enum :
    forall (sz : nat) (A B : Type) (ta : t A sz) (tb : t B sz),
      encoder B -> encoder (BoundedIndex ta).
  Variable decode_enum :
    forall (sz : nat) (A B : Type) (ta : t A sz) (tb : t B sz),
      decoder B -> decoder (BoundedIndex ta).
  Axiom encode_decode_enum :
    forall sz A B (ta : t A sz) tb B_predicate (B_encode : encoder B) (B_decode : decoder B) pred,
      encode_decode_correct cache transformer B_predicate B_encode B_decode ->
      encode_decode_correct cache transformer pred (encode_enum tb B_encode)
                                                   (decode_enum ta tb B_decode).

  Variable QType_Ws : t (word 16) 66.
  Variable QClass_Ws : t (word 16) 4.
  Variable RRecordType_Ws : t (word 16) 59.
  Variable RRecordClass_Ws : t (word 16) 3.
  Variable Opcode_Ws : t (word 4) 4.
  Variable RCODE_Ws : t (word 4) 12.

  Definition encode_question (q : question) :=
       encode_list encode_string q!"qname"
  Then encode_enum QType_Ws encode_word q!"qtype"
  Then encode_enum QClass_Ws encode_word q!"qclass"
  Done.

  Definition encode_SOA_RDATA (soa : SOA_RDATA) :=
       encode_list encode_string soa!"sourcehost"
  Then encode_list encode_string soa!"contact_email"
  Then encode_word soa!"serial"
  Then encode_word soa!"refresh"
  Then encode_word soa!"retry"
  Then encode_word soa!"expire"
  Then encode_word soa!"minTTL"
  Done.

  Definition encode_WKS_RDATA (wks : WKS_RDATA) :=
       encode_word wks!"Address"
  Then encode_word wks!"Protocol"
  Then encode_list encode_word wks!"Bit-Map"
  Done.

  Definition encode_HINFO_RDATA (hinfo : HINFO_RDATA) :=
       encode_string hinfo!"CPU"
  Then encode_string hinfo!"OS"
  Done.

  Definition encode_MX_RDATA (mx : MX_RDATA) :=
       encode_word mx!"Preference"
  Then encode_list encode_string mx!"Exchange"
  Done.

  Definition encode_rdata : encoder RDataType :=
  encode_SumType ResourceRecordTypeTypes
  (icons encode_word
  (icons (encode_list encode_string)
  (icons (encode_list encode_string)
  (icons encode_SOA_RDATA
  (icons encode_WKS_RDATA
  (icons (encode_list encode_string)
  (icons encode_HINFO_RDATA
  (icons (encode_list encode_string)
  (icons encode_MX_RDATA (icons encode_string inil)))))))))).

  Definition encode_resource (r : resourceRecord) :=
       encode_list encode_string r!sNAME
  Then encode_enum RRecordType_Ws encode_word r!sTYPE
  Then encode_enum RRecordClass_Ws encode_word r!sCLASS
  Then encode_word r!sTTL
  Then encode_rdata r!sRDATA
  Done.

  Definition encode_packet (p : packet) :=
       encode_word p!"id"
  Then encode_word (WS p!"QR" WO)
  Then encode_enum Opcode_Ws encode_word p!"Opcode"
  Then encode_word (WS p!"AA" WO)
  Then encode_word (WS p!"TC" WO)
  Then encode_word (WS p!"RD" WO)
  Then encode_word (WS p!"RA" WO)
  Then encode_word (WS false (WS false (WS false WO))) (* 3 bits reserved for future use *)
  Then encode_enum RCODE_Ws encode_word p!"RCODE"
  Then encode_nat 16 1 (* length of question field *)
  Then encode_nat 16 (|p!"answers"|)
  Then encode_nat 16 (|p!"authority"|)
  Then encode_nat 16 (|p!"additional"|)
  Then encode_question p!"question"
  Then encode_list encode_resource p!"answers"
  Then encode_list encode_resource p!"additional"
  Then encode_list encode_resource p!"authority"
  Done.

  Definition packet_decoder
  : { decode | encode_decode_correct cache transformer (fun _ => True) encode_packet decode }.
  Proof.
    eexists.

    eapply compose_encode_correct.
      eapply Word_decode_correct.
      solve_predicate. intro.

      eapply compose_encode_correct.
      eapply Word_decode_correct.
      solve_predicate. intro.

      eapply compose_encode_correct.
      eapply encode_decode_enum.
      eapply Word_decode_correct.
      solve_predicate. intro.

    eapply compose_encode_correct.
    eapply Word_decode_correct.
      solve_predicate. intro.

      eapply compose_encode_correct.
      eapply Word_decode_correct.
      solve_predicate. intro.

    eapply compose_encode_correct.
    eapply Word_decode_correct.
      solve_predicate. intro.

    eapply compose_encode_correct.
    eapply Word_decode_correct.
      solve_predicate. intro.

    eapply compose_encode_correct.
    eapply Word_decode_correct.
      solve_predicate. intro.

    eapply compose_encode_correct.
    eapply encode_decode_enum.
    eapply Word_decode_correct.
      solve_predicate. intro.

    eapply compose_encode_correct.
      eapply Nat_decode_correct.
      admit. intro.

    eapply compose_encode_correct.
      eapply Nat_decode_correct.
      admit. intro.

    eapply compose_encode_correct.
      eapply Nat_decode_correct.
      admit. intro.

    eapply compose_encode_correct.
    eapply Nat_decode_correct.
    admit. intro.

    eapply compose_encode_correct.
  Abort.
  (*{ unfold encode_question.
      eapply compose_encode_correct.

      eapply FixList_decode_correct.
      eapply String_decode_correct.
      simpl.
      solve_predicate.
    eapply Nat_decode_correct.
    admit. intro.

    solve_predicate. intro.

    eapply compose_encode_correct.
      eapply encode_decode_nat.
      solve_predicate. intro.

    eapply compose_encode_correct.
      instantiate (2:=fun _ => True).
      eapply compose_encode_correct.
        eapply encode_decode_list. eapply encode_decode_string.
        solve_predicate. intro.

      eapply compose_encode_correct.
        eapply encode_decode_enum. eapply encode_decode_word.
        solve_predicate. intro.

      eapply compose_encode_correct.
        eapply encode_decode_enum. eapply encode_decode_word.
        solve_predicate. intro.

      intros ? ? ? ? data ? ? ? ?.
      instantiate (1:=fun l b e => (_ l, b, e)).
      repeat destruct data as [? data].
      intros. simpl in *.
      cbv in H0.
      repeat match goal with
             | H : (_, _) = (_, _) |- _ => inversion H; subst; clear H
             | H : _ /\ _ |- _ => inversion H; subst; clear H
             end.
      intuition eauto. symmetry. eauto.
      solve_predicate. intro.

    eapply compose_encode_correct.
      instantiate (2:=fun _ => True).
      eapply encode_decode_list.
      eapply compose_encode_correct.
        eapply encode_decode_list. eapply encode_decode_string.
        solve_predicate. intro.

      eapply compose_encode_correct.
        eapply encode_decode_enum. eapply encode_decode_word.
        solve_predicate. intro.

      eapply compose_encode_correct.
        eapply encode_decode_enum. eapply encode_decode_word.
        solve_predicate. intro.

      eapply compose_encode_correct.
        eapply encode_decode_word.
        solve_predicate. intro.

      intros ? ? ? ? data ? ? ? ?. Show Existentials.
      instantiate (1:=fun l b e => (<"Name" :: proj13,
                                     sTYPE :: proj14,
                                     sCLASS :: proj15,
                                     sTTL :: l>, b, e)).
      simpl. intros. repeat match goal with
                            | H : (_, _) = (_, _) |- _ => inversion H; subst; clear H
                            | H : _ /\ _ |- _ => inversion H; subst; clear H
                            end. admit.
      solve_predicate. intro. *)
End DnsPacket.
