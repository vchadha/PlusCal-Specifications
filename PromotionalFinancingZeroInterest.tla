------------------ MODULE PromotionalFinancingZeroInterest ------------------
(***************************************************************************)
(*                          all stuff in cents                             *)
(***************************************************************************)
EXTENDS Integers, Sequences, TLC

\* MACROS
\* TODO make these procedures

\*DebitAmount(amount, bucket) ==
\*    [due |-> bucket.due, paid |-> bucket.paid + amount ]
\*
\*CreditAmount(amount, bucket) ==
\*    [due |-> bucket.due + amount, paid |-> bucket.paid ]
\*
\*DebitAndCreditAmount(amount, bucket) ==
\*    [due |-> bucket.due - amount, paid |-> bucket.paid + amount ]
\*
\*CreditAndDebitAmount(amount, bucket) ==
\*    [due |-> bucket.due + amount, paid |-> bucket.paid - amount ]

(****************************************************************************

--algorithm ZeroInterestPromotionalFinancing
{
    variables journal = <<>> \* Journal to record transactions - do I need/want this if i can see all states?
                
                \* Promotional Financing Offer
                , financedAmount = 10000 \* $100
                , apr = 25 \* 25%
                , numInstallments = 4
                , amountDuePerInstallment = 2500 \* $25
                
                \* TODO: not sure how to use this just yet (per installment or after promotion ends?)
                , gracePeriod
                
                \* Track status of promotion
                , cycleDay = 0
                , pfStatus = "Open"
                
                \* Double entry buckets
                , principalBucket = [ due |-> financedAmount, paid |-> 0 ]
                , interestBucket = [ due |-> 0, paid |-> 0 ]
                , feeBucket = [ due |-> 0, paid |-> 0 ]
                , initialAccountBudget = 10000 \* TODO: make this a constant
                , checkingAccountBucket = [ due |-> 0, paid |-> initialAccountBudget ]
                
                \* Max Constants to specify total time and payment options
                , MaxCycles = 6 \* TODO: maybe make this in numInstallments..numInstallments + 2 or something
                , PossiblePaymentAmounts = { 0, 100, 1000, 2500, 50000, 75000, 10000 };
    
    procedure DebitAmount( amount, toBucket, fromBucket )
    {
        skip;
    }; 
    
    {
        \* Go through every cycle until MaxCycles in reached (e.g. timebox the simulation)
        while ( cycleDay < MaxCycles )
        {
            \* Select amount to pay this cycle
            with ( amt \in PossiblePaymentAmounts )
            {
                \* Record transaction in our journal
                journal := Append(journal, [day |-> cycleDay,
                                            amount |-> amt]);
                
                \* Make payment
\*                principalBucket := DebitAndCreditAmount( amt, principalBucket );
            };
            
            cycleDay := cycleDay + 1;
        };
        

    }
}

****************************************************************************)
\* BEGIN TRANSLATION (chksum(pcal) = "8f744eab" /\ chksum(tla) = "7b294ed4")
CONSTANT defaultInitValue
VARIABLES journal, financedAmount, apr, numInstallments, 
          amountDuePerInstallment, gracePeriod, cycleDay, pfStatus, 
          principalBucket, interestBucket, feeBucket, initialAccountBudget, 
          checkingAccountBucket, MaxCycles, PossiblePaymentAmounts, pc, stack, 
          amount, toBucket, fromBucket

vars == << journal, financedAmount, apr, numInstallments, 
           amountDuePerInstallment, gracePeriod, cycleDay, pfStatus, 
           principalBucket, interestBucket, feeBucket, initialAccountBudget, 
           checkingAccountBucket, MaxCycles, PossiblePaymentAmounts, pc, 
           stack, amount, toBucket, fromBucket >>

Init == (* Global variables *)
        /\ journal = <<>>
        /\ financedAmount = 10000
        /\ apr = 25
        /\ numInstallments = 4
        /\ amountDuePerInstallment = 2500
        /\ gracePeriod = defaultInitValue
        /\ cycleDay = 0
        /\ pfStatus = "Open"
        /\ principalBucket = [ due |-> financedAmount, paid |-> 0 ]
        /\ interestBucket = [ due |-> 0, paid |-> 0 ]
        /\ feeBucket = [ due |-> 0, paid |-> 0 ]
        /\ initialAccountBudget = 10000
        /\ checkingAccountBucket = [ due |-> 0, paid |-> initialAccountBudget ]
        /\ MaxCycles = 6
        /\ PossiblePaymentAmounts = { 0, 100, 1000, 2500, 50000, 75000, 10000 }
        (* Procedure DebitAmount *)
        /\ amount = defaultInitValue
        /\ toBucket = defaultInitValue
        /\ fromBucket = defaultInitValue
        /\ stack = << >>
        /\ pc = "Lbl_2"

Lbl_1 == /\ pc = "Lbl_1"
         /\ TRUE
         /\ pc' = "Error"
         /\ UNCHANGED << journal, financedAmount, apr, numInstallments, 
                         amountDuePerInstallment, gracePeriod, cycleDay, 
                         pfStatus, principalBucket, interestBucket, feeBucket, 
                         initialAccountBudget, checkingAccountBucket, 
                         MaxCycles, PossiblePaymentAmounts, stack, amount, 
                         toBucket, fromBucket >>

DebitAmount == Lbl_1

Lbl_2 == /\ pc = "Lbl_2"
         /\ IF cycleDay < MaxCycles
               THEN /\ \E amt \in PossiblePaymentAmounts:
                         journal' = Append(journal, [day |-> cycleDay,
                                                     amount |-> amt])
                    /\ cycleDay' = cycleDay + 1
                    /\ pc' = "Lbl_2"
               ELSE /\ pc' = "Done"
                    /\ UNCHANGED << journal, cycleDay >>
         /\ UNCHANGED << financedAmount, apr, numInstallments, 
                         amountDuePerInstallment, gracePeriod, pfStatus, 
                         principalBucket, interestBucket, feeBucket, 
                         initialAccountBudget, checkingAccountBucket, 
                         MaxCycles, PossiblePaymentAmounts, stack, amount, 
                         toBucket, fromBucket >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == DebitAmount \/ Lbl_2
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 

=============================================================================
\* Modification History
\* Last modified Sat May 03 13:44:36 PDT 2025 by vchadha
\* Created Fri May 02 19:43:23 PDT 2025 by vchadha
