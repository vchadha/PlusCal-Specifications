------------------------- MODULE GlobalTableLWW -----------------------------
(***************************************************************************)
(* Specifies the behavior of a DynamoDB Global Table under eventual        *)
(* consistency with last-writer-wins (LWW) conflict resolution.            *)
(*                                                                         *)
(* Each region accepts application writes using optimistic locking         *)
(* (a key may only be written once per region). Writes are replicated to   *)
(* all other regions. Because replication is asynchronous, two regions can *)
(* independently write the same key, causing a conflict. LWW resolves the  *)
(* conflict by keeping the write with the highest timestamp.               *)
(*                                                                         *)
(* When LWW overwrites an existing item, DynamoDB generates a MODIFY       *)
(* stream record containing the original writer's region. We verify:       *)
(*                                                                         *)
(*  Completeness: Every LWW overwrite produces a MODIFY record.            *)
(*  Soundness:    MODIFY records only appear when an overwrite occurred.   *)
(***************************************************************************)
EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
    Regions,              \* Set of region identifiers — define as model values
                          \* in the cfg e.g. {east, west}
    TotalWritesPerRegion  \* Writes per region. Keys are derived as 1..TotalWritesPerRegion
                          \* so every region writes every key exactly once,
                          \* guaranteeing a conflict on every key across all regions.

ASSUME Regions /= {}
ASSUME Cardinality(Regions) >= 2
ASSUME TotalWritesPerRegion \in Nat /\ TotalWritesPerRegion > 0

\* Keys are monotonically increasing integers derived from TotalWritesPerRegion.
Keys == 1..TotalWritesPerRegion

-----------------------------------------------------------------------------
\* Data constructors

\* Sentinel for a db slot that has never been written to
NoWriter == "NONE"
NoItem   == [ts |-> 0, writer |-> NoWriter]

\* A database item written at logical timestamp t by region w
DBItem(t, w) == [ts |-> t, writer |-> w]

\* A pending replication event: key k was written at timestamp t by region w
ReplEvent(k, t, w) == [key |-> k, ts |-> t, writer |-> w]

\* A DynamoDB Streams record: type tp (insert, modify, etc.) for key k in region src
StreamRec(tp, k, src) == [type |-> tp, key |-> k, source |-> src]

-----------------------------------------------------------------------------

(*--algorithm DynamoDBGlobalTable {

    \* db[r][k]         — the current item at key k in region r, or NoItem.
    \* repl_queue[r]    — set of pending replication events for region r.
    \*                    An unordered set (not a sequence) so TLC explores
    \*                    all possible delivery orderings between regions.
    \* streams[r]       — the stream records generated in region r.
    \* global_clock     — logical clock, incremented on every application write.
    \*                    Gives each write a unique timestamp without needing
    \*                    per-region clocks or tie-breaking logic.
    \* was_overwritten  — auxiliary tracking variable (does not exist in the
    \*                    real system). Records whether a replication overwrite
    \*                    has ever occurred for a given (region, key) pair.
    \*                    The invariants are defined against this variable.
    variables
        db              = [r \in Regions |-> [k \in Keys |-> NoItem]],
        repl_queue      = [r \in Regions |-> {}],
        streams         = [r \in Regions |-> <<>>],
        global_clock    = 0,
        was_overwritten = [r \in Regions |-> [k \in Keys |-> FALSE]];

    \* One process per region. Each iteration nondeterministically either
    \* performs an application write or processes one replication event.
    \* A process naturally becomes permanently blocked (terminates) when
    \* its writes are exhausted AND its queue is empty.
    process (region \in Regions)
    variable writes_done = 0;
    {
    Loop:
        while (TRUE) {
            either {

                \* ============================================================
                \* APPLICATION WRITE
                \*
                \* Optimistic locking check: pick any key not yet written in
                \* this region. Because Keys == 1..TotalWritesPerRegion, every
                \* region writes every key exactly once, guaranteeing a conflict
                \* on every key across all regions.
                \* ============================================================
AppWrite:       when writes_done < TotalWritesPerRegion;
                \* This simulates the optimistic lock by forcibly choosing
                \* a key that has not been written to yet.
                with (k \in {key \in Keys : db[self][key] = NoItem}) {
                    with (t = global_clock + 1) {
                        global_clock  := t;
                        db[self][k]   := DBItem(t, self);
                        repl_queue    := [rr \in Regions |->
                                            IF rr /= self
                                            THEN repl_queue[rr] \cup {ReplEvent(k, t, self)}
                                            ELSE repl_queue[rr]];
                        streams[self] := Append(streams[self], StreamRec("INSERT", k, self));
                        writes_done   := writes_done + 1;
                    }
                }

            } or {

                \* ============================================================
                \* APPLY REPLICATION
                \*
                \* Pick any pending event nondeterministically (unordered set
                \* models arbitrary delivery ordering). Three cases:
                \*
                \*  No local item:        pure INSERT, no conflict.
                \*  Incoming ts > local:  LWW overwrite — apply the incoming
                \*                        item, emit MODIFY record with the
                \*                        original writer's region as source.
                \*  Incoming ts <= local: stale event — drop silently.
                \*                        No stream record is emitted.
                \* ============================================================
ApplyRepl:      when repl_queue[self] /= {};
                with (event \in repl_queue[self]) {
                    repl_queue[self] := repl_queue[self] \ {event};
                    if (db[self][event.key] = NoItem) {
                        db[self][event.key] := DBItem(event.ts, event.writer);
                        streams[self]       := Append(streams[self],
                                                StreamRec("INSERT", event.key, event.writer));
                    } else if (event.ts > db[self][event.key].ts) {
                        db[self][event.key]              := DBItem(event.ts, event.writer);
                        streams[self]                    := Append(streams[self],
                                                             StreamRec("MODIFY", event.key, event.writer));
                        was_overwritten[self][event.key] := TRUE;
                    };
                    \* else: stale — drop silently, was_overwritten unchanged
                }

            }
        }
    }
}*)

\* BEGIN TRANSLATION
VARIABLES pc, db, repl_queue, streams, global_clock, was_overwritten, 
          writes_done

vars == << pc, db, repl_queue, streams, global_clock, was_overwritten, 
           writes_done >>

ProcSet == (Regions)

Init == (* Global variables *)
        /\ db = [r \in Regions |-> [k \in Keys |-> NoItem]]
        /\ repl_queue = [r \in Regions |-> {}]
        /\ streams = [r \in Regions |-> <<>>]
        /\ global_clock = 0
        /\ was_overwritten = [r \in Regions |-> [k \in Keys |-> FALSE]]
        (* Process region *)
        /\ writes_done = [self \in Regions |-> 0]
        /\ pc = [self \in ProcSet |-> "Loop"]

Loop(self) == /\ pc[self] = "Loop"
              /\ \/ /\ pc' = [pc EXCEPT ![self] = "AppWrite"]
                 \/ /\ pc' = [pc EXCEPT ![self] = "ApplyRepl"]
              /\ UNCHANGED << db, repl_queue, streams, global_clock, 
                              was_overwritten, writes_done >>

AppWrite(self) == /\ pc[self] = "AppWrite"
                  /\ writes_done[self] < TotalWritesPerRegion
                  /\ \E k \in {key \in Keys : db[self][key] = NoItem}:
                       LET t == global_clock + 1 IN
                         /\ global_clock' = t
                         /\ db' = [db EXCEPT ![self][k] = DBItem(t, self)]
                         /\ repl_queue' = [rr \in Regions |->
                                             IF rr /= self
                                             THEN repl_queue[rr] \cup {ReplEvent(k, t, self)}
                                             ELSE repl_queue[rr]]
                         /\ streams' = [streams EXCEPT ![self] = Append(streams[self], StreamRec("INSERT", k, self))]
                         /\ writes_done' = [writes_done EXCEPT ![self] = writes_done[self] + 1]
                  /\ pc' = [pc EXCEPT ![self] = "Loop"]
                  /\ UNCHANGED was_overwritten

ApplyRepl(self) == /\ pc[self] = "ApplyRepl"
                   /\ repl_queue[self] /= {}
                   /\ \E event \in repl_queue[self]:
                        /\ repl_queue' = [repl_queue EXCEPT ![self] = repl_queue[self] \ {event}]
                        /\ IF db[self][event.key] = NoItem
                              THEN /\ db' = [db EXCEPT ![self][event.key] = DBItem(event.ts, event.writer)]
                                   /\ streams' = [streams EXCEPT ![self] = Append(streams[self],
                                                                            StreamRec("INSERT", event.key, event.writer))]
                                   /\ UNCHANGED was_overwritten
                              ELSE /\ IF event.ts > db[self][event.key].ts
                                         THEN /\ db' = [db EXCEPT ![self][event.key] = DBItem(event.ts, event.writer)]
                                              /\ streams' = [streams EXCEPT ![self] = Append(streams[self],
                                                                                       StreamRec("MODIFY", event.key, event.writer))]
                                              /\ was_overwritten' = [was_overwritten EXCEPT ![self][event.key] = TRUE]
                                         ELSE /\ TRUE
                                              /\ UNCHANGED << db, streams, 
                                                              was_overwritten >>
                   /\ pc' = [pc EXCEPT ![self] = "Loop"]
                   /\ UNCHANGED << global_clock, writes_done >>

region(self) == Loop(self) \/ AppWrite(self) \/ ApplyRepl(self)

Next == (\E self \in Regions: region(self))

Spec == Init /\ [][Next]_vars

\* END TRANSLATION

-----------------------------------------------------------------------------
\* Helper

\* True if streams[r] contains at least one MODIFY record for key k
HasModifyRecord(r, k) ==
    \E i \in 1..Len(streams[r]):
        /\ streams[r][i].type = "MODIFY"
        /\ streams[r][i].key = k

-----------------------------------------------------------------------------
\* Invariants

TypeOK ==
    /\ global_clock    \in Nat
    /\ was_overwritten \in [Regions -> [Keys -> BOOLEAN]]

\* Completeness: every LWW overwrite produces a MODIFY stream record
Completeness ==
    \A r \in Regions, k \in Keys:
        was_overwritten[r][k] => HasModifyRecord(r, k)

\* Soundness: MODIFY records only appear when an actual overwrite occurred
Soundness ==
    \A r \in Regions, k \in Keys:
        HasModifyRecord(r, k) => was_overwritten[r][k]

=============================================================================
