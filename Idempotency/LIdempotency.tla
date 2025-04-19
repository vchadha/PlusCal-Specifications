---------------------------- MODULE LIdempotency ----------------------------
(***************************************************************************)
(* This module contains an algorithm for a service that                    *)
(* implements Idempotency.                                                 *)
(*                                                                         *)
(* We define the following invariants:                                     *)
(*                                                                         *)
(*  1. New items are always written to the db with monotonically           *)
(*      increasing indecies starting from 0.                               *)
(*  2. If there are two concurrent requests, one will succeed and one      *)
(*      will fail since they will both try to write to index N + 1         *)
(*      and no overwrites are allowed.                                     *)
(*                                                                         *)
(* Idempotency defines the following invariant:                            *)
(*                                                                         *)
(*  1. If multiple requests are sent with the same unique id, one          *)
(*      will be processed and the other will not.                          *)
(***************************************************************************)
EXTENDS Integers, Sequences

CONSTANT UniqueRequests, TotalRequests
    ASSUME UniqueRequests \in Nat
    ASSUME UniqueRequests > 0
    ASSUME TotalRequests \in Nat

\* Write to database
\*  newItem = item to append to head of database
\*  db = database sequence
\*  Output: new database with item prepended
DBWrite(newItem, db) == << newItem >> \o db

\* DBEmpty
\*  db = database sequence
\*  Output: True if database is empty
DBEmpty(db) == Len(db) = 0

\* Get latest item
\*  db = database sequence
\*  Output: Head of database.
GetLatestItem(db) == IF DBEmpty(db) THEN << >> ELSE Head(db)

\* Idempotency query
\*  uniqueId = id for request
\*  db = database sequence
\*  Output: True if command is idempotent (we have seen it before)
IdempotencyCheck(uniqueId, db) ==
    { i \in 1..Len(db) : uniqueId = db[i][2] } /= {}

\* Optimistic locking check
\*  index = int representing id of database item
\*  db = database sequence
\*  Output: True if no item has given index in the database
OptimisticLock(index, db) == { j \in 1..Len(db) : index = db[j][1] } = {}

(****************************************************************************

--algorithm Idempotency
{
    \* db is a sequence of tuples: << index, unique id >>
    variables db = << >>, Requests = 1..TotalRequests;

    \* Each process handles a request
    process (request \in Requests)

    variables uniqueId = self % UniqueRequests,
    
              latestItem = << >>,
              idempotentCheck = FALSE,
              newItem = << >>,
              
              doneProcessing = FALSE;
    {
proc:   while ( ~doneProcessing )
        {   
            \* Get latest item in database
getItem:    latestItem := GetLatestItem(db);
                
            \* Check if request id has been seen before
idempCheck: idempotentCheck := IdempotencyCheck(uniqueId, db);
                
handle:     if ( ~idempotentCheck )
            {
                \* Create new item
                newItem := IF latestItem = << >>
                            THEN << 0, uniqueId >>
                            ELSE << latestItem[1] + 1, uniqueId >>;
                    
                \* Optimistic locking check - has anyone taken new index
write:          if ( OptimisticLock(newItem[1], db) )
                {
                    db := DBWrite(newItem, db);
                    doneProcessing := TRUE;
                }
            }
            else
            {
                doneProcessing := TRUE;
            }
        }
    }
}

****************************************************************************)

\* BEGIN TRANSLATION (chksum(pcal) = "6ffc5cd2" /\ chksum(tla) = "4582a346")
VARIABLES db, Requests, pc, uniqueId, latestItem, idempotentCheck, newItem, 
          doneProcessing

vars == << db, Requests, pc, uniqueId, latestItem, idempotentCheck, newItem, 
           doneProcessing >>

ProcSet == (Requests)

Init == (* Global variables *)
        /\ db = << >>
        /\ Requests = 1..TotalRequests
        (* Process request *)
        /\ uniqueId = [self \in Requests |-> self % UniqueRequests]
        /\ latestItem = [self \in Requests |-> << >>]
        /\ idempotentCheck = [self \in Requests |-> FALSE]
        /\ newItem = [self \in Requests |-> << >>]
        /\ doneProcessing = [self \in Requests |-> FALSE]
        /\ pc = [self \in ProcSet |-> "proc"]

proc(self) == /\ pc[self] = "proc"
              /\ IF ~doneProcessing[self]
                    THEN /\ pc' = [pc EXCEPT ![self] = "getItem"]
                    ELSE /\ pc' = [pc EXCEPT ![self] = "Done"]
              /\ UNCHANGED << db, Requests, uniqueId, latestItem, 
                              idempotentCheck, newItem, doneProcessing >>

getItem(self) == /\ pc[self] = "getItem"
                 /\ latestItem' = [latestItem EXCEPT ![self] = GetLatestItem(db)]
                 /\ pc' = [pc EXCEPT ![self] = "idempCheck"]
                 /\ UNCHANGED << db, Requests, uniqueId, idempotentCheck, 
                                 newItem, doneProcessing >>

idempCheck(self) == /\ pc[self] = "idempCheck"
                    /\ idempotentCheck' = [idempotentCheck EXCEPT ![self] = IdempotencyCheck(uniqueId[self], db)]
                    /\ pc' = [pc EXCEPT ![self] = "handle"]
                    /\ UNCHANGED << db, Requests, uniqueId, latestItem, 
                                    newItem, doneProcessing >>

handle(self) == /\ pc[self] = "handle"
                /\ IF ~idempotentCheck[self]
                      THEN /\ newItem' = [newItem EXCEPT ![self] = IF latestItem[self] = << >>
                                                                    THEN << 0, uniqueId[self] >>
                                                                    ELSE << latestItem[self][1] + 1, uniqueId[self] >>]
                           /\ pc' = [pc EXCEPT ![self] = "write"]
                           /\ UNCHANGED doneProcessing
                      ELSE /\ doneProcessing' = [doneProcessing EXCEPT ![self] = TRUE]
                           /\ pc' = [pc EXCEPT ![self] = "proc"]
                           /\ UNCHANGED newItem
                /\ UNCHANGED << db, Requests, uniqueId, latestItem, 
                                idempotentCheck >>

write(self) == /\ pc[self] = "write"
               /\ IF OptimisticLock(newItem[self][1], db)
                     THEN /\ db' = DBWrite(newItem[self], db)
                          /\ doneProcessing' = [doneProcessing EXCEPT ![self] = TRUE]
                     ELSE /\ TRUE
                          /\ UNCHANGED << db, doneProcessing >>
               /\ pc' = [pc EXCEPT ![self] = "proc"]
               /\ UNCHANGED << Requests, uniqueId, latestItem, idempotentCheck, 
                               newItem >>

request(self) == proc(self) \/ getItem(self) \/ idempCheck(self)
                    \/ handle(self) \/ write(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Requests: request(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

\* Invariants
DBSize == Len(db) <= UniqueRequests 

IndexOrder == (Len(db) > 1) => \A i \in 1..Len(db): (i + 1 <= Len(db)) => db[i][1] - 1 = db[i + 1][1]

IdUniqueness == (Len(db) > 1) => ( \A i, j \in 1..Len(db): (i /= j) => db[i][2] /= db[j][2] )

FinalDBSize == (\A self \in ProcSet: pc[self] = "Done") => Len(db) = UniqueRequests

=============================================================================
\* Modification History
\* Last modified Sat Apr 12 22:45:40 CDT 2025 by vchadha
\* Created Mon Mar 24 13:40:16 CDT 2025 by vchadha
