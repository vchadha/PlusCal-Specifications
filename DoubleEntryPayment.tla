------------------------- MODULE DoubleEntryPayment -------------------------
EXTENDS Integers, Sequences

(****************************************************************************

--algorithm FinancialSim
{
    variables day = 0,
          journal = <<>>,
          cashBalance = 1000,
          payablesBalance = 0,
          
          MaxDays = 4,
          MaxAmountPerPayment = 2;

    {
        while ( day < MaxDays )
        {
            with ( amt \in 1..MaxAmountPerPayment )
            {
                journal := Append(journal, [day |-> day,
                                            amount |-> amt]);
                
                cashBalance := cashBalance - amt;
                payablesBalance := payablesBalance - amt;
            };
            
            day := day + 1;
        };
    }
}

****************************************************************************)
\* BEGIN TRANSLATION (chksum(pcal) = "e5518c2f" /\ chksum(tla) = "583e9bd5")
VARIABLES day, journal, cashBalance, payablesBalance, MaxDays, 
          MaxAmountPerPayment, pc

vars == << day, journal, cashBalance, payablesBalance, MaxDays, 
           MaxAmountPerPayment, pc >>

Init == (* Global variables *)
        /\ day = 0
        /\ journal = <<>>
        /\ cashBalance = 1000
        /\ payablesBalance = 0
        /\ MaxDays = 4
        /\ MaxAmountPerPayment = 2
        /\ pc = "Lbl_1"

Lbl_1 == /\ pc = "Lbl_1"
         /\ IF day < MaxDays
               THEN /\ \E amt \in 1..MaxAmountPerPayment:
                         /\ journal' = Append(journal, [day |-> day,
                                                        amount |-> amt])
                         /\ cashBalance' = cashBalance - amt
                         /\ payablesBalance' = payablesBalance - amt
                    /\ day' = day + 1
                    /\ pc' = "Lbl_1"
               ELSE /\ pc' = "Done"
                    /\ UNCHANGED << day, journal, cashBalance, payablesBalance >>
         /\ UNCHANGED << MaxDays, MaxAmountPerPayment >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Lbl_1
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 

=============================================================================
\* Modification History
\* Last modified Thu May 01 19:14:42 PDT 2025 by vchadha
\* Created Wed Apr 30 19:24:43 PDT 2025 by vchadha
