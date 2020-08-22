from libc.stdint cimport uint64_t

cdef int NUM_ROWS
cdef int NUM_COLS
cdef int MAX_DEPTH

cdef list EXP_ORDER

cdef bint check_winning_position(uint64_t position)
cdef (uint64_t, uint64_t) take_turn(uint64_t position, uint64_t mask, int col)
cdef (uint64_t, uint64_t) take_turn_move(uint64_t position, uint64_t mask, uint64_t move)
cdef list legal_moves(uint64_t mask)
cdef int move_score(uint64_t position, uint64_t mask, uint64_t move)
cdef uint64_t possible_non_losing_moves(uint64_t position, uint64_t mask)
cdef uint64_t possible_moves(uint64_t mask)
cdef uint64_t opponent_winning_position(uint64_t position, uint64_t mask)
cdef uint64_t can_win_next(uint64_t position, uint64_t mask)
cdef uint64_t column_mask(int column)
cdef uint64_t key3(uint64_t position, uint64_t mask)
cdef (uint64_t, uint64_t) key3_to_pos_and_mask(uint64_t key3)
cpdef void print_board(uint64_t position, uint64_t mask, bint show_scores, bint cur_player)
cpdef (uint64_t, uint64_t) from_game_string(str game_string)
cpdef void mask_check()