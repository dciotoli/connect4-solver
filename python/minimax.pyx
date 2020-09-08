from libc.stdint cimport uint8_t, uint64_t
cimport board
from transposition_table cimport TranspositionTable, UPPER_BOUND_FLAG, EXACT_FLAG,\
    LOWER_BOUND_FLAG, STATE_VALUE_MASK, STATE_VALUE_OFFSET
from move_sorter cimport SortedMoveList
from opening_book cimport load_book_file

cdef int NUM_ROWS = 6
cdef int NUM_COLS = 7
cdef int MAX_DEPTH = (NUM_ROWS * NUM_COLS)
cdef int MIN_SCORE = -(NUM_ROWS*NUM_COLS)//2 + 3
cdef int MAX_SCORE = (NUM_ROWS*NUM_COLS+1)//2 - 3
cdef unsigned int TT_SIZE = 10388593

cdef dict opening_book = {}
cdef TranspositionTable tt = TranspositionTable(TT_SIZE)


cdef int alpha_beta_negamax_search(uint64_t position, uint64_t mask, int alpha, int beta) except * :
    cdef uint64_t new_pos, new_mask, non_losing_moves, key, key3, move = 0
    cdef int score, alphaOrig, column, true_val, min_score, depth, p1_stones_played, p2_stones_played
    cdef uint8_t val, tt_flag
    cdef SortedMoveList moves = SortedMoveList()
    cdef list move_order = []

    depth = board.popcount(mask)
    p1_stones_played = board.popcount(position)
    p2_stones_played = depth - p1_stones_played

    if depth >= MAX_DEPTH:
        # Draw
        return 0

    assert alpha < beta

    if board.can_win_next(position, mask):
        return ((NUM_COLS * NUM_ROWS) // 2) - p1_stones_played

    # assert not board.can_win_next(position, mask)

    alphaOrig = alpha
    min_score = -(((NUM_COLS * NUM_ROWS) // 2) - p2_stones_played)

    moves.reset()
    non_losing_moves = board.possible_non_losing_moves(position, mask)

    if not non_losing_moves:
        return min_score

    # Check if key is in the precalculated set
    key3 = board.key3(position, mask)
    score = opening_book.get(key3, -999)
    if score != -999:
        if depth != 10:
            raise RuntimeError(f'Depth was not 10! Depth was: {depth}')
        return score

    key = position + mask
    val = tt.get(key)

    if val:
        true_val = (val & STATE_VALUE_MASK) - STATE_VALUE_OFFSET
        if val & EXACT_FLAG:
            # Exact value
            return true_val
        elif val & UPPER_BOUND_FLAG:
            # Upper bound
            beta = min(beta, true_val)
        else:
            # Lower bound
            alpha = max(alpha, true_val)

        if alpha >= beta:
            return true_val

    # Order moves
    for column in board.EXP_ORDER:
        if non_losing_moves & board.column_mask(column):
            moves.add(non_losing_moves & board.column_mask(column),
                board.move_score(position, mask, non_losing_moves & board.column_mask(column)))

    assert moves.size > 0
    move = moves.getNext()
    assert non_losing_moves != 0
    assert move != 0

    score = min_score
    while move:
        new_pos, new_mask = board.take_turn_move(position, mask, move)
        score = max(score, -alpha_beta_negamax_search(new_pos, new_mask, -beta, -alpha))
        alpha = max(alpha, score)
        if alpha >= beta:
            break

        move = moves.getNext()

    moves.reset()
    assert (score + STATE_VALUE_OFFSET) <= 63 and (score + STATE_VALUE_OFFSET) >= 0

    if score <= alphaOrig:
        tt_flag = UPPER_BOUND_FLAG
    elif score >= beta:
        tt_flag = LOWER_BOUND_FLAG
    else:
        tt_flag = EXACT_FLAG

    tt.put(key, <uint8_t> (score + STATE_VALUE_OFFSET) | tt_flag)

    return score


cpdef int score_move(uint64_t position, uint64_t mask, int col, bint aspirational_search=0) except *:
    cdef uint64_t new_pos, new_mask
    cdef int min_val, max_val, med, r, depth, p1_stones_played, p2_stones_played

    depth = board.popcount(mask)
    p1_stones_played = board.popcount(position)
    p2_stones_played = depth - p1_stones_played

    # Check if valid move (if not return -99)
    if not (board.possible_moves(mask) & board.column_mask(col)):
        return -99

    new_pos, new_mask = board.take_turn(position, mask, col)

    # Did we win?
    if board.check_winning_position(new_pos ^ new_mask):
        return ((NUM_COLS * NUM_ROWS) // 2) - p1_stones_played

    # Check opponent can win next
    if board.can_win_next(new_pos, new_mask):
        return -(((NUM_COLS * NUM_ROWS) // 2) - p2_stones_played)

    min_val = -(NUM_COLS * NUM_ROWS - (depth + 1)) // 2
    max_val = (NUM_COLS * NUM_ROWS - depth) // 2

    if not aspirational_search:
        return -alpha_beta_negamax_search(new_pos, new_mask, min_val, max_val)
    else:
        while min_val < max_val:
            med = min_val + ((max_val - min_val) // 2)
            if (med <= 0 and (min_val // 2) < med):
                med = min_val // 2
            elif (med >= 0 and (max_val // 2) > med):
                med = max_val // 2
            # use a null depth window to know if the actual score is greater or smaller than med
            r = alpha_beta_negamax_search(new_pos, new_mask, med, med + 1)
            if (r <= med):
                max_val = r
            else:
                min_val = r

    return -min_val


cpdef void init_opening_book(book_file):
    global opening_book
    load_book_file(opening_book, book_file)