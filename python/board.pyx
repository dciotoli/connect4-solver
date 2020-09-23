from numpy import mean
from libc.stdint cimport uint64_t
from libc.stdio cimport printf
import numpy as np

cdef int NUM_ROWS = 6
cdef int NUM_COLS = 7
cdef list EXP_ORDER = [i for i in range(NUM_COLS)]
cdef int col_mean = int(mean(EXP_ORDER))

EXP_ORDER.sort(key = lambda x: abs(x - col_mean))


# "Static" bitmaps
cdef uint64_t bottom(int width, int height):
    return 0 if width == 0 else bottom(width-1, height) | 1LL << (width-1)*(height+1)

cdef uint64_t column_mask(int col):
    return ((1LL << NUM_ROWS)-1) << (col*(NUM_ROWS+1))

cdef uint64_t bottom_mask = bottom(NUM_COLS, NUM_ROWS);
cdef uint64_t board_mask = bottom_mask * ((1LL << NUM_ROWS)-1)


cpdef void print_board(uint64_t position, uint64_t mask, bint show_scores, bint cur_player):
    cdef uint64_t bitmask
    cdef bytes marker
    cdef bytes KRED = b'\x1B[31m'
    cdef bytes KBLU = b'\x1B[34m'
    cdef bytes RESET = b'\x1B[0m'
    cdef bytes color

    printf(bytes(''.join([f' {i} ' for i in range(NUM_COLS)]) + '\n', encoding='utf-8'))
    printf((b'_'*NUM_COLS*3) + b'\n')
    for i in range(NUM_ROWS):
        for j in range(NUM_COLS):
            bitmask = 1LL << ((NUM_ROWS - 1 - i) + (NUM_COLS * j))
            if bitmask & position & mask:
                marker = b'X' if cur_player else b'O'
                color = KRED if cur_player else KBLU
            elif bitmask & (position ^ mask):
                marker = b'O' if cur_player else b'X'
                color = KBLU if cur_player else KRED
            else:
                marker = b'.'
                color = b''
            printf(b' %s%s%s ', color, marker, RESET)
        printf(b'\n')
    printf(b'\n')


cpdef void mask_check():
    print_board(bottom_mask, bottom_mask, 1, 1)
    print_board(board_mask, board_mask, 1, 1)


cdef bint check_winning_position(uint64_t position):
    # Horizontal check
    cdef uint64_t m = position & (position >> 7)
    if m & (m >> 14):
        return True

    # Diagonal \
    m = position & (position >> 6)
    if m & (m >> 12):
        return True

    # Diagonal /
    m = position & (position >> 8)
    if m & (m >> 16):
        return True

    # Vertical
    m = position & (position >> 1)
    if m & (m >> 2):
        return True

    # Nothing found
    return False


cdef (uint64_t, uint64_t) take_turn(uint64_t position, uint64_t mask, int col):
    cdef uint64_t new_pos = position ^ mask
    cdef uint64_t new_mask = mask | (mask + (1LL << (col * (NUM_ROWS + 1))))

    return new_pos, new_mask


cdef (uint64_t, uint64_t) take_turn_move(uint64_t position, uint64_t mask, uint64_t move):
    cdef uint64_t new_pos = position ^ mask
    cdef uint64_t new_mask = mask | move

    return new_pos, new_mask


cdef list legal_moves(uint64_t mask):
    # return columns which are legal
    cdef list moves = []
    for i in EXP_ORDER:
        if mask ^ (1 << ((NUM_ROWS + 1) * (i + 1)) - 2):
            moves.append(i)

    return moves


cdef uint64_t compute_winning_position(uint64_t position, uint64_t mask):
        # vertical;
        cdef uint64_t r = (position << 1) & (position << 2) & (position << 3)

        # horizontal
        cdef uint64_t p = (position << (NUM_ROWS+1)) & (position << 2*(NUM_ROWS+1))
        r |= p & (position << 3*(NUM_ROWS+1))
        r |= p & (position >> (NUM_ROWS+1))
        p = (position >> (NUM_ROWS+1)) & (position >> 2*(NUM_ROWS+1))
        r |= p & (position << (NUM_ROWS+1))
        r |= p & (position >> 3*(NUM_ROWS+1))

        # diagonal 1
        p = (position << NUM_ROWS) & (position << 2*NUM_ROWS)
        r |= p & (position << 3*NUM_ROWS)
        r |= p & (position >> NUM_ROWS)
        p = (position >> NUM_ROWS) & (position >> 2*NUM_ROWS)
        r |= p & (position << NUM_ROWS)
        r |= p & (position >> 3*NUM_ROWS)

        # diagonal 2
        p = (position << (NUM_ROWS+2)) & (position << 2*(NUM_ROWS+2))
        r |= p & (position << 3*(NUM_ROWS+2))
        r |= p & (position >> (NUM_ROWS+2))
        p = (position >> (NUM_ROWS+2)) & (position >> 2*(NUM_ROWS+2))
        r |= p & (position << (NUM_ROWS+2))
        r |= p & (position >> 3*(NUM_ROWS+2))

        return r & (board_mask ^ mask)


cdef uint64_t opponent_winning_position(uint64_t position, uint64_t mask):
    return compute_winning_position(position ^ mask, mask)


cdef uint64_t possible_moves(uint64_t mask):
    return (mask + bottom_mask) & board_mask


cdef uint64_t can_win_next(uint64_t position, uint64_t mask):
    return compute_winning_position(position, mask) & possible_moves(mask)


cdef uint64_t possible_non_losing_moves(uint64_t position, uint64_t mask):
    assert can_win_next(position, mask) == 0

    cdef uint64_t possible_mask = possible_moves(mask)
    cdef uint64_t opponent_win = opponent_winning_position(position, mask)
    cdef uint64_t forced_moves = possible_mask & opponent_win
    if forced_moves:
        if (forced_moves & (forced_moves - 1)):     # check if there is more than one forced move
            return 0                                # the opponnent has two winning moves and you cannot stop him
        else: possible_mask = forced_moves          # enforce to play the single forced move

    return possible_mask & ~(opponent_win >> 1) # avoid to play below an opponent winning spot


cdef unsigned int popcount(uint64_t m):
    cdef unsigned int c = 0
    while m:
        m &= m - 1
        c += 1

    return c


cdef int move_score(uint64_t current_position, uint64_t mask, uint64_t move):
    return popcount(compute_winning_position(current_position | move, mask))


cdef void partialkey3(uint64_t * key, uint64_t current_position, uint64_t mask, int col):
    cdef uint64_t pos = 1LL << (col * (NUM_ROWS + 1))

    while pos & mask:
        key[0] *= 3LL
        if pos & current_position:
            key[0] += 1LL
        else:
            key[0] += 2LL
        pos <<= 1

    key[0] *= 3LL

    return


cdef uint64_t key3(uint64_t position, uint64_t mask):
    cdef int col
    cdef uint64_t key_fwd = 0
    cdef uint64_t key_bwd = 0

    for col in range(NUM_COLS):
        partialkey3(&key_fwd, position, mask, col)
        partialkey3(&key_bwd, position, mask, NUM_COLS - col - 1)

    return min(key_fwd, key_bwd) // 3


cdef (uint64_t, uint64_t) key3_to_pos_and_mask(uint64_t key3):
    cdef uint64_t pos = 0, mask = 0
    cdef unsigned int col = 0, digit
    # iterate through base 3 numbers,
    while key3:
        digit = key3 % 3
        key3 /= 3
        if digit == 0:
            col += 1
        elif digit == 1:
            # Move position column up by one
            pos = (pos & ~column_mask(col)) | ((pos & column_mask(col)) << 1)
            pos |= pos + (bottom_mask & column_mask(col))
            mask |= mask + (bottom_mask & column_mask(col))
        elif digit == 2:
            # Move position column up by one
            pos = (pos & ~column_mask(col)) | ((pos & column_mask(col)) << 1)
            mask |= mask + (bottom_mask & column_mask(col))
    return pos, mask


cpdef (uint64_t, uint64_t) from_game_string(str game_string):
    cdef uint64_t pos = 0, mask = 0
    for x in game_string:
        pos, mask = take_turn(pos, mask, int(x)-1)

    return pos, mask