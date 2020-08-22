from libc.stdio cimport printf
from libc.stdlib cimport malloc, free


# ToDo: get rid of many mallocs, just have 1 at initialization with max expected size, re-use linked list structure

cdef class SortedMoveList:
    cdef void add(self, uint64_t move, int score) except *:
        cdef ScoredMove * cur = <ScoredMove *> NULL
        cdef ScoredMove * prev = <ScoredMove *> NULL
        cdef ScoredMove * new_move = <ScoredMove *> malloc(sizeof(ScoredMove))
        if not new_move:
            raise MemoryError()

        new_move.move = move
        new_move.score = score
        new_move.next = NULL

        # Check if head exists
        if not self.entries:
            self.entries = new_move
            self.size += 1
            return

        cur = self.entries
        while cur and score <= cur.score:
            prev = cur
            cur = cur.next

        if cur:
            new_move.next = cur

        if prev:
            prev.next = new_move
        else:
            self.entries = new_move

        self.size += 1

        return

    cdef uint64_t getNext(self):
        cdef uint64_t move = 0
        cdef ScoredMove * new_head = <ScoredMove *> NULL

        # Pop the front node off, free it, and decrement size
        if self.entries:
            move = self.entries.move
            new_head = self.entries.next
            free(self.entries)
            self.entries = new_head
            self.size -= 1

        return move

    cdef void print_moves(self):
        cdef ScoredMove * cur = <ScoredMove *> NULL
        cdef ScoredMove * next = <ScoredMove *> NULL

        # loop through and free all nodes
        cur = self.entries
        while cur:
            printf(b'%d:%llu -> ', cur.score, cur.move)
            cur = cur.next
        printf('\n')
        return

    cdef void reset(self):
        cdef ScoredMove * cur = <ScoredMove *> NULL
        cdef ScoredMove * next = <ScoredMove *> NULL

        # loop through and free all nodes
        cur = self.entries
        while cur:
            next = cur.next
            free(cur)
            cur = next
            self.size -= 1
        assert self.size == 0
        return

cpdef test_move_sorter():
    cdef SortedMoveList moves = SortedMoveList()
    cdef uint64_t move
    cdef list scores = [1, 1, 1, 1, 1, 2, 2]
    cdef int column

    printf(b'\n###########################\n')
    printf(b'### TESTING MOVE SORTER ###\n')
    printf(b'###########################\n\n')
    printf(b'Testing reverse insert...\n')
    for column in range(7):
        moves.add(<uint64_t> column+1, scores[column])

    printf(b'Result of print_moves...\n')
    moves.print_moves()

    printf(b'Result of iteration...\n')
    move = moves.getNext()
    while move:
        printf(b'Move: %llu\n', move)
        move = moves.getNext()

    moves.reset()
    printf(b'\n###############################\n')
    printf(b'### END TESTING MOVE SORTER ###\n')
    printf(b'###############################\n')
    return