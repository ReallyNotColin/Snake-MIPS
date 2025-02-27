
.data
# Game Core information
screenWidth:      .word 64
screenHeight:     .word 64

# Colors
snakeColor:       .word 0x0066cc   # blue
whiteColor:       .word 0xFFFFFF   # white
backgroundColor:  .word 0x000000   # black
borderColor:      .word 0x00ff00   # green
fruitColor:       .word 0xcc6611   # orange

# Score variables
score:            .word 0
scoreGain:        .word 10
gameSpeed:        .word 200
scoreMilestones:  .word 100, 250, 500, 1000, 5000, 10000
scoreArrayPosition: .word 0
lostMessage:      .asciiz "You have died.... Your score was: "
replayMessage:    .asciiz "Would you like to replay?"

# Snake Information
snakeHeadX:       .word 31
snakeHeadY:       .word 31
snakeTailX:       .word 31
snakeTailY:       .word 37
direction:        .word 119    # initially moving up (ASCII 'w')
tailDirection:    .word 119
# Arrays to store direction change coordinates and new directions:
directionChangeAddressArray: .word 0:100
newDirectionChangeArray:     .word 0:100
arrayPosition:                .word 0
locationInArray:              .word 0

# Fruit Information
fruitPositionX:   .word 0
fruitPositionY:   .word 0

.text
.globl main
main:
    # Fill screen with background color (black)
    lw   $a0, screenWidth
    lw   $a1, backgroundColor
    mul  $a2, $a0, $a0    # total number of pixels on screen
    mul  $a2, $a2, 4      # 4 bytes per pixel
    add  $a2, $a2, $gp    # add base of display
    add  $a0, $gp, $zero
FillLoop:
    beq  $a0, $a2, Init
    sw   $a1, 0($a0)
    addiu $a0, $a0, 4
    j    FillLoop

Init:
    li   $t0, 31
    sw   $t0, snakeHeadX
    sw   $t0, snakeHeadY
    sw   $t0, snakeTailX
    li   $t0, 37
    sw   $t0, snakeTailY
    li   $t0, 119
    sw   $t0, direction
    sw   $t0, tailDirection
    li   $t0, 10
    sw   $t0, scoreGain
    li   $t0, 200
    sw   $t0, gameSpeed
    sw   $zero, arrayPosition
    sw   $zero, locationInArray
    sw   $zero, scoreArrayPosition
    sw   $zero, score

ClearRegisters:
    li $v0, 0
    li $a0, 0
    li $a1, 0
    li $a2, 0
    li $a3, 0
    li $t0, 0
    li $t1, 0
    li $t2, 0
    li $t3, 0
    li $t4, 0
    li $t5, 0
    li $t6, 0
    li $t7, 0
    li $t8, 0
    li $t9, 0
    li $s0, 0
    li $s1, 0
    li $s2, 0
    li $s3, 0
    li $s4, 0

# Draw Border around the 64x64 screen
DrawBorder:
    # Left border (x = 0)
    li   $t1, 0
LeftLoop:
    move $a1, $t1
    li   $a0, 0
    jal  CoordinateToAddress
    move $a0, $v0
    lw   $a1, borderColor
    jal  DrawPixel
    add  $t1, $t1, 1
    bne  $t1, 64, LeftLoop

    # Right border (x = 63)
    li   $t1, 0
RightLoop:
    move $a1, $t1
    li   $a0, 63
    jal  CoordinateToAddress
    move $a0, $v0
    lw   $a1, borderColor
    jal  DrawPixel
    add  $t1, $t1, 1
    bne  $t1, 64, RightLoop

    # Top border (y = 0)
    li   $t1, 0
TopLoop:
    move $a0, $t1   # x coordinate
    li   $a1, 0    # y coordinate
    jal  CoordinateToAddress
    move $a0, $v0
    lw   $a1, borderColor
    jal  DrawPixel
    add  $t1, $t1, 1
    bne  $t1, 64, TopLoop

    # Bottom border (y = 63)
    li   $t1, 0
BottomLoop:
    move $a0, $t1
    li   $a1, 63
    jal  CoordinateToAddress
    move $a0, $v0
    lw   $a1, borderColor
    jal  DrawPixel
    add  $t1, $t1, 1
    bne  $t1, 64, BottomLoop

# Draw the initial snake using DrawSnakePixel for alternating colors.
DrawInitialSnake:
    # Draw snake head
    lw   $a0, snakeHeadX
    lw   $a1, snakeHeadY
    jal  DrawSnakePixel

    # Draw body segments (for example, 6 segments below head)
    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    addiu $t1, $t1, 1
    move $a0, $t0
    move $a1, $t1
    jal  DrawSnakePixel

    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    addiu $t1, $t1, 2
    move $a0, $t0
    move $a1, $t1
    jal  DrawSnakePixel

    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    addiu $t1, $t1, 3
    move $a0, $t0
    move $a1, $t1
    jal  DrawSnakePixel

    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    addiu $t1, $t1, 4
    move $a0, $t0
    move $a1, $t1
    jal  DrawSnakePixel

    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    addiu $t1, $t1, 5
    move $a0, $t0
    move $a1, $t1
    jal  DrawSnakePixel

    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    addiu $t1, $t1, 6
    move $a0, $t0
    move $a1, $t1
    jal  DrawSnakePixel

    # Draw snake tail
    lw   $a0, snakeTailX
    lw   $a1, snakeTailY
    jal  DrawSnakePixel

    j SpawnFruit

SpawnFruit:
    # Generate X coordinate
    li   $v0, 42         # random integer syscall
    li   $a1, 62         # set upper bound (0 <= value < 62)
    syscall              # returns random integer in $a0
    addiu $a0, $a0, 1    # adjust to avoid border
    sw   $a0, fruitPositionX

    # Generate Y coordinate
    li   $v0, 42         # reinitialize syscall
    li   $a1, 62
    syscall
    addiu $a0, $a0, 1    # adjust to avoid border
    sw   $a0, fruitPositionY

    jal  IncreaseDifficulty

InputCheck:
    lw   $a0, gameSpeed
    jal  Pause

    # Get coordinates for direction change at snake head.
    lw   $a0, snakeHeadX
    lw   $a1, snakeHeadY
    jal  CoordinateToAddress
    add  $a2, $v0, $zero

    # Get keyboard input.
    li   $t0, 0xffff0000
    lw   $t1, ($t0)
    andi $t1, $t1, 0x0001
    beqz $t1, SelectDrawDirection
    lw   $a1, 4($t0)    # new direction input

DirectionCheck:
    lw   $a0, direction
    jal  CheckDirection
    beqz $v0, InputCheck
    sw   $a1, direction
    lw   $t7, direction

SelectDrawDirection:
    beq  $t7, 119, DrawUpLoop
    beq  $t7, 115, DrawDownLoop
    beq  $t7, 97,  DrawLeftLoop
    beq  $t7, 100, DrawRightLoop
    j    InputCheck

# Each movement routine now calls collision check before updating the head.
DrawUpLoop:
    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    lw   $a2, direction
    move $a0, $t0
    move $a1, $t1
    jal  CheckGameEndingCollision   # check collision for current head position
    # update head for upward movement
    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    addiu $t1, $t1, -1
    sw   $t1, snakeHeadY
    move $a0, $t0
    move $a1, $t1
    jal  DrawSnakePixel
    j    UpdateTailPosition

DrawDownLoop:
    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    lw   $a2, direction
    move $a0, $t0
    move $a1, $t1
    jal  CheckGameEndingCollision
    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    addiu $t1, $t1, 1
    sw   $t1, snakeHeadY
    move $a0, $t0
    move $a1, $t1
    jal  DrawSnakePixel
    j    UpdateTailPosition

DrawLeftLoop:
    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    lw   $a2, direction
    move $a0, $t0
    move $a1, $t1
    jal  CheckGameEndingCollision
    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    addiu $t0, $t0, -1
    sw   $t0, snakeHeadX
    move $a0, $t0
    move $a1, $t1
    jal  DrawSnakePixel
    j    UpdateTailPosition

DrawRightLoop:
    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    lw   $a2, direction
    move $a0, $t0
    move $a1, $t1
    jal  CheckGameEndingCollision
    lw   $t0, snakeHeadX
    lw   $t1, snakeHeadY
    addiu $t0, $t0, 1
    sw   $t0, snakeHeadX
    move $a0, $t0
    move $a1, $t1
    jal  DrawSnakePixel
    j    UpdateTailPosition

UpdateTailPosition:
    lw   $t2, tailDirection
    beq  $t2, 119, MoveTailUp
    beq  $t2, 115, MoveTailDown
    beq  $t2, 97,  MoveTailLeft
    beq  $t2, 100, MoveTailRight
    j    DrawFruit

MoveTailUp:
    lw   $t8, locationInArray
    la   $t0, directionChangeAddressArray
    add  $t0, $t0, $t8
    lw   $t9, 0($t0)
    lw   $a0, snakeTailX
    lw   $a1, snakeTailY
    beq  $s1, 1, IncreaseLengthUp
    addiu $a1, $a1, -1
    sw   $a1, snakeTailY
IncreaseLengthUp:
    li   $s1, 0
    jal  CoordinateToAddress
    add  $a0, $v0, $zero
    bne  $t9, $a0, DrawTailUp_Label
    la   $t3, newDirectionChangeArray
    add  $t3, $t3, $t8
    lw   $t9, 0($t3)
    sw   $t9, tailDirection
    addiu $t8, $t8, 4
    bne  $t8, 396, StoreLocationUp
    li   $t8, 0
StoreLocationUp:
    sw   $t8, locationInArray
DrawTailUp_Label:
    lw   $a0, snakeTailX
    lw   $a1, snakeTailY
    jal  DrawSnakePixel
    lw   $t0, snakeTailX
    lw   $t1, snakeTailY
    addiu $t1, $t1, 1
    move $a0, $t0
    move $a1, $t1
    jal  CoordinateToAddress
    move $a0, $v0
    lw   $a1, backgroundColor
    jal  DrawPixel
    j    DrawFruit

MoveTailDown:
    lw   $t8, locationInArray
    la   $t0, directionChangeAddressArray
    add  $t0, $t0, $t8
    lw   $t9, 0($t0)
    lw   $a0, snakeTailX
    lw   $a1, snakeTailY
    beq  $s1, 1, IncreaseLengthDown
    addiu $a1, $a1, 1
    sw   $a1, snakeTailY
IncreaseLengthDown:
    li   $s1, 0
    jal  CoordinateToAddress
    add  $a0, $v0, $zero
    bne  $t9, $a0, DrawTailDown_Label
    la   $t3, newDirectionChangeArray
    add  $t3, $t3, $t8
    lw   $t9, 0($t3)
    sw   $t9, tailDirection
    addiu $t8, $t8, 4
    bne  $t8, 396, StoreLocationDown
    li   $t8, 0
StoreLocationDown:
    sw   $t8, locationInArray
DrawTailDown_Label:
    lw   $a0, snakeTailX
    lw   $a1, snakeTailY
    jal  DrawSnakePixel
    lw   $t0, snakeTailX
    lw   $t1, snakeTailY
    addiu $t1, $t1, -1
    move $a0, $t0
    move $a1, $t1
    jal  CoordinateToAddress
    move $a0, $v0
    lw   $a1, backgroundColor
    jal  DrawPixel
    j    DrawFruit

MoveTailLeft:
    lw   $t8, locationInArray
    la   $t0, directionChangeAddressArray
    add  $t0, $t0, $t8
    lw   $t9, 0($t0)
    lw   $a0, snakeTailX
    lw   $a1, snakeTailY
    beq  $s1, 1, IncreaseLengthLeft
    addiu $a0, $a0, -1
    sw   $a0, snakeTailX
IncreaseLengthLeft:
    li   $s1, 0
    jal  CoordinateToAddress
    add  $a0, $v0, $zero
    bne  $t9, $a0, DrawTailLeft_Label
    la   $t3, newDirectionChangeArray
    add  $t3, $t3, $t8
    lw   $t9, 0($t3)
    sw   $t9, tailDirection
    addiu $t8, $t8, 4
    bne  $t8, 396, StoreLocationLeft
    li   $t8, 0
StoreLocationLeft:
    sw   $t8, locationInArray
DrawTailLeft_Label:
    lw   $a0, snakeTailX
    lw   $a1, snakeTailY
    jal  DrawSnakePixel
    lw   $t0, snakeTailX
    lw   $t1, snakeTailY
    addiu $t0, $t0, 1
    move $a0, $t0
    move $a1, $t1
    jal  CoordinateToAddress
    move $a0, $v0
    lw   $a1, backgroundColor
    jal  DrawPixel
    j    DrawFruit

MoveTailRight:
    lw   $t8, locationInArray
    la   $t0, directionChangeAddressArray
    add  $t0, $t0, $t8
    lw   $t9, 0($t0)
    lw   $a0, snakeTailX
    lw   $a1, snakeTailY
    beq  $s1, 1, IncreaseLengthRight
    addiu $a0, $a0, 1
    sw   $a0, snakeTailX
IncreaseLengthRight:
    li   $s1, 0
    jal  CoordinateToAddress
    add  $a0, $v0, $zero
    bne  $t9, $a0, DrawTailRight_Label
    la   $t3, newDirectionChangeArray
    add  $t3, $t3, $t8
    lw   $t9, 0($t3)
    sw   $t9, tailDirection
    addiu $t8, $t8, 4
    bne  $t8, 396, StoreLocationRight
    li   $t8, 0
StoreLocationRight:
    sw   $t8, locationInArray
DrawTailRight_Label:
    lw   $a0, snakeTailX
    lw   $a1, snakeTailY
    jal  DrawSnakePixel
    lw   $t0, snakeTailX
    lw   $t1, snakeTailY
    addiu $t0, $t0, -1
    move $a0, $t0
    move $a1, $t1
    jal  CoordinateToAddress
    move $a0, $v0
    lw   $a1, backgroundColor
    jal  DrawPixel
    j    DrawFruit

DrawFruit:
    lw   $a0, snakeHeadX
    lw   $a1, snakeHeadY
    jal  CheckFruitCollision
    beq  $v0, 1, AddLength
    lw   $a0, fruitPositionX
    lw   $a1, fruitPositionY
    jal  CoordinateToAddress
    move $a0, $v0
    lw   $a1, fruitColor
    jal  DrawPixel
    j    InputCheck

AddLength:
    li   $s1, 1
    j    SpawnFruit

j InputCheck

##################################################################
# CoordinateToAddress Function
#  $a0 -> x coordinate, $a1 -> y coordinate
#  Returns $v0 as the display memory address.
CoordinateToAddress:
    lw   $v0, screenWidth
    mul  $v0, $v0, $a1
    add  $v0, $v0, $a0
    mul  $v0, $v0, 4
    add  $v0, $v0, $gp
    jr   $ra

##################################################################
# DrawPixel Function
#  $a0 -> Address, $a1 -> Color
DrawPixel:
    sw   $a1, 0($a0)
    jr   $ra

##################################################################
# DrawSnakePixel Function (Method 2: Coordinate-Based Coloring)
#  Input: $a0 = x coordinate, $a1 = y coordinate
#  Chooses the color based on (x+y) mod 2:
#     if 0, use blue (snakeColor); else use white (whiteColor).
DrawSnakePixel:
    add   $t0, $a0, $a1        # compute sum = x + y
    andi  $t0, $t0, 1          # (x+y) mod 2
    beq   $t0, $zero, UseBlue_Snake
    lw    $t1, whiteColor      # use white if (x+y) mod 2 != 0
    j     ContinueDrawSnake
UseBlue_Snake:
    lw    $t1, snakeColor      # use blue otherwise
ContinueDrawSnake:
    # Compute display address from (x,y)
    lw    $t2, screenWidth
    mul   $t2, $t2, $a1
    add   $t2, $t2, $a0
    mul   $t2, $t2, 4
    add   $t2, $t2, $gp
    move  $a0, $t2
    move  $a1, $t1
    # Save return address before calling DrawPixel
    addi  $sp, $sp, -4
    sw    $ra, 0($sp)
    jal   DrawPixel
    lw    $ra, 0($sp)
    addi  $sp, $sp, 4
    jr    $ra

##################################################################
# Check Acceptable Direction
#  $a0: current direction, $a1: new input, $a2: coordinate for direction change
#  Returns $v0 = 1 if acceptable, 0 if not.
CheckDirection:
    beq  $a0, $a1, Same
    beq  $a0, 119, checkIsDownPressed
    beq  $a0, 115, checkIsUpPressed
    beq  $a0, 97,  checkIsRightPressed
    beq  $a0, 100, checkIsLeftPressed
    j    DirectionCheckFinished

checkIsDownPressed:
    beq  $a1, 115, unacceptable
    j    acceptable

checkIsUpPressed:
    beq  $a1, 119, unacceptable
    j    acceptable

checkIsRightPressed:
    beq  $a1, 100, unacceptable
    j    acceptable

checkIsLeftPressed:
    beq  $a1, 97, unacceptable
    j    acceptable

acceptable:
    li   $v0, 1
    beq  $a1, 119, storeUpDirection
    beq  $a1, 115, storeDownDirection
    beq  $a1, 97, storeLeftDirection
    beq  $a1, 100, storeRightDirection
    j    DirectionCheckFinished

storeUpDirection:
    lw   $t4, arrayPosition
    la   $t2, directionChangeAddressArray
    la   $t3, newDirectionChangeArray
    add  $t2, $t2, $t4
    add  $t3, $t3, $t4
    sw   $a2, 0($t2)
    li   $t5, 119
    sw   $t5, 0($t3)
    addiu $t4, $t4, 4
    bne  $t4, 396, UpStop
    li   $t4, 0
UpStop:
    sw   $t4, arrayPosition
    j    DirectionCheckFinished

storeDownDirection:
    lw   $t4, arrayPosition
    la   $t2, directionChangeAddressArray
    la   $t3, newDirectionChangeArray
    add  $t2, $t2, $t4
    add  $t3, $t3, $t4
    sw   $a2, 0($t2)
    li   $t5, 115
    sw   $t5, 0($t3)
    addiu $t4, $t4, 4
    bne  $t4, 396, DownStop
    li   $t4, 0
DownStop:
    sw   $t4, arrayPosition
    j    DirectionCheckFinished

storeLeftDirection:
    lw   $t4, arrayPosition
    la   $t2, directionChangeAddressArray
    la   $t3, newDirectionChangeArray
    add  $t2, $t2, $t4
    add  $t3, $t3, $t4
    sw   $a2, 0($t2)
    li   $t5, 97
    sw   $t5, 0($t3)
    addiu $t4, $t4, 4
    bne  $t4, 396, LeftStop
    li   $t4, 0
LeftStop:
    sw   $t4, arrayPosition
    j    DirectionCheckFinished

storeRightDirection:
    lw   $t4, arrayPosition
    la   $t2, directionChangeAddressArray
    la   $t3, newDirectionChangeArray
    add  $t2, $t2, $t4
    add  $t3, $t3, $t4
    sw   $a2, 0($t2)
    li   $t5, 100
    sw   $t5, 0($t3)
    addiu $t4, $t4, 4
    bne  $t4, 396, RightStop
    li   $t4, 0
RightStop:
    sw   $t4, arrayPosition
    j    DirectionCheckFinished

unacceptable:
    li   $v0, 0
    j    DirectionCheckFinished

Same:
    li   $v0, 1

DirectionCheckFinished:
    jr   $ra

##################################################################
# Pause Function
#  $a0: pause duration
Pause:
    li   $v0, 32
    syscall
    jr   $ra

##################################################################
# Check Fruit Collision
#  $a0: snakeHead X, $a1: snakeHead Y
#  Returns $v0: 1 if collision, 0 otherwise.
CheckFruitCollision:
    lw   $t0, fruitPositionX
    lw   $t1, fruitPositionY
    add  $v0, $zero, $zero
    beq  $a0, $t0, XEqualFruit
    j    ExitCollisionCheck
XEqualFruit:
    beq  $a1, $t1, YEqualFruit
    j    ExitCollisionCheck
YEqualFruit:
    lw   $t5, score
    lw   $t6, scoreGain
    add  $t5, $t5, $t6
    sw   $t5, score
    li   $v0, 31
    li   $a0, 79
    li   $a1, 150
    li   $a2, 7
    li   $a3, 127
    syscall
    li   $a0, 96
    li   $a1, 250
    li   $a2, 7
    li   $a3, 127
    syscall
    li   $v0, 1
ExitCollisionCheck:
    jr   $ra

##################################################################
# Check Snake Body Collision
#  $a0: snakeHead X, $a1: snakeHead Y, $a2: snakeHead direction
#  Returns $v0: 1 if collision (with snake or border), 0 otherwise.
CheckGameEndingCollision:
    add  $s3, $a0, $zero
    add  $s4, $a1, $zero
    sw   $ra, 0($sp)
    beq  $a2, 119, CheckUp
    beq  $a2, 115, CheckDown
    beq  $a2, 97,  CheckLeft
    beq  $a2, 100, CheckRight
    j    BodyCollisionDone

CheckUp:
    addiu $a1, $a1, -1
    jal  CoordinateToAddress
    lw   $t1, 0($v0)
    lw   $t2, snakeColor
    lw   $t3, borderColor
    lw   $t4, whiteColor
    beq  $t1, $t2, Exit
    beq  $t1, $t3, Exit
    beq  $t1, $t4, Exit
    j    BodyCollisionDone

CheckDown:
    addiu $a1, $a1, 1
    jal  CoordinateToAddress
    lw   $t1, 0($v0)
    lw   $t2, snakeColor
    lw   $t3, borderColor
    lw   $t4, whiteColor
    beq  $t1, $t2, Exit
    beq  $t1, $t3, Exit
    beq  $t1, $t4, Exit
    j    BodyCollisionDone

CheckLeft:
    addiu $a0, $a0, -1
    jal  CoordinateToAddress
    lw   $t1, 0($v0)
    lw   $t2, snakeColor
    lw   $t3, borderColor
    lw   $t4, whiteColor
    beq  $t1, $t2, Exit
    beq  $t1, $t3, Exit
    beq  $t1, $t4, Exit
    j    BodyCollisionDone

CheckRight:
    addiu $a0, $a0, 1
    jal  CoordinateToAddress
    lw   $t1, 0($v0)
    lw   $t2, snakeColor
    lw   $t3, borderColor
    lw   $t4, whiteColor
    beq  $t1, $t2, Exit
    beq  $t1, $t3, Exit
    beq  $t1, $t4, Exit
    j    BodyCollisionDone

BodyCollisionDone:
    lw   $ra, 0($sp)
    jr   $ra

##################################################################
# Increase Difficulty Function
IncreaseDifficulty:
    lw   $t0, score
    la   $t1, scoreMilestones
    lw   $t2, scoreArrayPosition
    add  $t1, $t1, $t2
    lw   $t3, 0($t1)
    bne  $t3, $t0, FinishedDiff
    addiu $t2, $t2, 4
    sw   $t2, scoreArrayPosition
    lw   $t0, scoreGain
    sll  $t0, $t0, 1
    lw   $t1, gameSpeed
    addiu $t1, $t1, -25
    sw   $t1, gameSpeed
FinishedDiff:
    jr   $ra

Exit:
    li   $v0, 31
    li   $a0, 28
    li   $a1, 250
    li   $a2, 32
    li   $a3, 127
    syscall
    li   $a0, 33
    li   $a1, 250
    li   $a2, 32
    li   $a3, 127
    syscall
    li   $a0, 47
    li   $a1, 1000
    li   $a2, 32
    li   $a3, 127
    syscall
    li   $v0, 56
    la   $a0, lostMessage
    lw   $a1, score
    syscall
    li   $v0, 50
    la   $a0, replayMessage
    syscall
    beqz $a0, main
    li   $v0, 10
    syscall
