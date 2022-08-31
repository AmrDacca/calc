.global	calc_expr
.section .data
result:.zero 21
str:.zero   1
str_length:
#parameters order
#1-%rdi pointer string convert pointer restult as string-%rsi
#using %rax,%rdx,%rsi,%rcx(as offset to the start of input string)
.section .text
calc_expr:
        pushq   %rbp
        movq    %rsp,%rbp
        subq    $20,%rsp
        movq    %rdi,-8(%rbp)
        movq    %rsi,-16(%rbp)
        movl    $0,-20(%rbp)
        #-21(%rbp) is the start of the string till '\0'
        movq    $-21,%rbx
INPUTCHAR:
        movq    $0,%rax
        movq    $0,%rdi
        leaq    str,%rsi
        movq    $1,%rdx
        syscall
        movb    str,%al
        movb    %al,(%rbp,%rbx,1)
        cmpb     $0x0A,%al  #if %al='\n'
        je      ENDINPUT
        decq    %rsp
        decq    %rbx
        jmp     INPUTCHAR
ENDINPUT:
#save the offset for the start of the input string
        movb    $0x00,(%rbp,%rbx,1)
        leaq    -21(%rbp),%rdi
        call    CountOpening
        movl    %eax,-20(%rbp)#save count to local value count
        movq    -8(%rbp),%rdi
        leaq    -21(%rbp),%rsi
        xorq    %rdx,%rdx
        movl    -20(%rbp),%edx
        call    Evaluate
       #we have the result of the calculation is result
        leaq    result,%rdi
        xorq    %rax,%rax
        call   *-8(%rbp)
        #we have the number in %rax
        movq    %rax,%rdi
        call   *-16(%rbp)
        movl    %eax,%edx
        movq    $1,%rax
        movq    $1,%rdi
        leaq    what_to_print,%rsi
        syscall
        leave
	ret


#WOOOOOOOOOOOOOOORKS#WOOOOOOOOOOOOOOORKS
NumberOfDigits:#num in %rdi##WOOOOOOOOOOOOOOORKS
#uses %rdx and %rax
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $16,%rsp 
        movq    $1,-8(%rbp)
        movq    $10,-16(%rbp)
        movq    %rdi,%rax
        xorq     %rdx,%rdx
        divq    -16(%rbp)
NumberOfDigitsWhile:
        cmpq    $0,%rax
        je      NumberOfDigitsEnd
        xorq    %rdx,%rdx
        incq    -8(%rbp)
        divq    -16(%rbp)
        jmp     NumberOfDigitsWhile
        
NumberOfDigitsEnd:
        movq    -8(%rbp),%rax
        leave
        ret


FindRightOperator:
#char* str in %rdi
#uses %rdx,%rax
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $8,%rsp
        movq    %rdi,-8(%rbp)#to move only the local value
        movq    -8(%rbp),%rax
FindRightOperatorWhile:
        movb    (%rax),%dl
        cmpb    $0x00,%dl#'\0'
        je      FindRightOperatorEnd
        cmpb    $0x29,%dl#')'
        je      FindRightOperatorEnd
        cmpb    $0x2A,%dl#'*'
        je      FindRightOperatorEnd
        cmpb    $0x2B,%dl#'+'
        je      FindRightOperatorEnd
        cmpb    $0x2D,%dl#'-'
        je      FindRightOperatorEnd
        cmpb    $0x2F,%dl#'/'
        je      FindRightOperatorEnd
        decq    %rax#because stack we start from high
        jmp     FindRightOperatorWhile
FindRightOperatorEnd:
        leave
        ret

FindLeftOperator:
#char* left_edge--%rdi ^ char* start --%rsi
#we use here %rax,%rdx
#%rax is tmp pointer to the start of string
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $8,%rsp
        movq    %rsi,-8(%rbp)
        incq    -8(%rbp)###################
        movq    -8(%rbp),%rax
FindLeftOperatorWhile:
        cmpq    %rdi,%rax#if they are equal then %rax=%rdi
        je      FindLeftOperatorEND#means left_edge=itr=start-1
        movb    (%rax),%dl
        cmpb    $0x28,%dl#'('
        je      FindLeftOperatorEND
        cmpb    $0x2A,%dl#'*'
        je      FindLeftOperatorEND
        cmpb    $0x2B,%dl#'+'
        je      FindLeftOperatorEND
        cmpb    $0x2D,%dl#'-'
        je      FindLeftOperatorEND
        cmpb    $0x2F,%dl#'/'
        je      FindLeftOperatorEND
        incq    %rax#because stack we start from high
        jmp     FindLeftOperatorWhile
FindLeftOperatorEND: 
        leave
        ret     

FindDivideOperator:
#char* start--%rdi ^ char* end --%rsi
#we use here %rax,%rdx
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $8,%rsp
        movq    %rdi,-8(%rbp)
        movq    -8(%rbp),%rax
FindDivideOperatorWhile:
        cmpq    %rsi,%rax
        je      FindDivideOperatorEND
        movb    (%rax),%dl
        cmpb    $0x2F,%dl#'/'
        je      FindDivideOperatorEND
        decq    %rax#because stack we start from high
        jmp     FindDivideOperatorWhile
FindDivideOperatorEND:
        leave
        ret
FindMultiOperator:
#char* start--%rdi ^ char* end --%rsi
#we use here %rax,%rdx
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $8,%rsp
        movq    %rdi,-8(%rbp)
        movq    -8(%rbp),%rax
FindMultiOperatorWhile:
        cmpq    %rsi,%rax
        je      FindMultiOperatorEND
        movb    (%rax),%dl
        cmpb    $0x2A,%dl#'*'
        je      FindMultiOperatorEND
        decq    %rax#because stack we start from high
        jmp     FindMultiOperatorWhile
FindMultiOperatorEND:
        leave
        ret




CountNumberOfMinus:
#char* start--%rdi ^ char* end --%rsi
#we use here %rax--return value,%rdx--local itr,%rcx--the value of string
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $12,%rsp#first 4 int last 8 char* tmp_start(itr)
        movl    $0,-4(%rbp)#local int
        movq    %rdi,-12(%rbp)#local start(itr)
        movq    -12(%rbp),%rdx#itr=start
        xorq    %rax,%rax
CountNumberOfMinusWhile:
        cmpq    %rsi,%rdx#if(itr=end)
        je      CountNumberOfMinusEND
        movb    (%rdx),%cl#cl=*itr
        cmpb    $0x2D,%cl#'-'
        jne     CountNumberOfMinusIncrease
        decq    %rdx
        incl    -4(%rbp)
        jmp     CountNumberOfMinusWhile
CountNumberOfMinusIncrease:
        decq    %rdx
        jmp     CountNumberOfMinusWhile
CountNumberOfMinusEND:
        movl    -4(%rbp),%eax
        leave
        ret        

FindLastOpening:
#char* start(str)--%rdi ^ int --%esi
#we use %rax,%rdx
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $12,%rsp#first 4 is int the last 8 is tmp_start(itr)
        movl    %esi,-4(%rbp)
        movq    %rdi,-12(%rbp)
        movq    -12(%rbp),%rax#tmp_start
        xorq    %rdx,%rdx
FindLastOpeningWhile:
        movb   (%rax),%dl
        cmpb    $0x00,%dl
        je      FindLastOpeningEnd
        cmpb    $0x28,%dl#'('
        je      ReduceCounter
        jmp     DontNotReduce
ReduceCounter:
        decl    -4(%rbp)
DontNotReduce:
        cmpl    $0,-4(%rbp)
        je      FindLastOpeningEnd
        decq    %rax
        jmp     FindLastOpeningWhile

FindLastOpeningEnd:
        leave
        ret


FindFirstClosing:
#char* start(str)--%rdi
#we use %rax as tmp itr,%rdx as the char(anychar)
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $8,%rsp
        movq    %rdi,-8(%rbp)
        movq    -8(%rbp),%rax
        xorq    %rdx,%rdx
FindFirstClosingWhile:
        movb   (%rax),%dl
        cmpb    $0x00,%dl
        je      FindFirstClosingEnd
        cmpb    $0x29,%dl#')'
        je      FindFirstClosingEnd
        decq    %rax
        jmp     FindFirstClosingWhile
        
FindFirstClosingEnd:
        leave
        ret
        
        
CountOpening:
#char* start(str)--%rdi
#we use %rax as tmp itr,%rdx as the char(anychar)
#return value in %eax
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $12,%rsp#first is int second is the tmp_start(itr)
        movl    $0,-4(%rbp)
        movq    %rdi,-12(%rbp)
        movq    -12(%rbp),%rax
CountOpeningWhile:
        movb   (%rax),%dl
        cmpb    $0x00,%dl
        je     CountOpeningEnd#was jmp because i am dumb
        cmpb    $0x28,%dl#'('
        je      IncreaseCounter
        jmp     WithoutIncreasing
IncreaseCounter:
        incl    -4(%rbp)
WithoutIncreasing:
        decq    %rax
        jmp     CountOpeningWhile
CountOpeningEnd:
        movl    -4(%rbp),%eax
        leave
        ret



FindMinusOperator:
#char* start--%rdi ^ char* end --%rsi
#we use here %rax,%rdx
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $8,%rsp
        movq    %rdi,-8(%rbp)
        movq    -8(%rbp),%rax
        xorq    %rdx,%rdx
FindMinusOperatorWhile:
        cmpq    %rsi,%rax
        je      FindMinusOperatorEnd
        movb    (%rax),%dl
        cmpb    $0x2D,%dl
        je      FindMinusOperatorEnd
        decq    %rax
        jmp     FindMinusOperatorWhile
FindMinusOperatorEnd:
        leave
        ret
               
FindPlusOperator:
#char* start--%rdi ^ char* end --%rsi
#we use here %rax,%rdx
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $8,%rsp
        movq    %rdi,-8(%rbp)
        movq    -8(%rbp),%rax
        xorq    %rdx,%rdx
FindPlusOperatorWhile:
        cmpq    %rsi,%rax
        je      FindPlusOperatorEnd
        movb    (%rax),%dl
        cmpb    $0x2B,%dl
        je      FindPlusOperatorEnd
        decq    %rax
        jmp     FindPlusOperatorWhile
FindPlusOperatorEnd:
        leave
        ret
        
        
OverRideSubString:
#char* start--%rdi ^ char* end --%rsi  ^  result(data) override_string %rdx
#here we dont care about the value of %rdx nor the value of start(%rdi)
#using %rcx,%rax,%r8    
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $29,%rsp   
        movq    %rsi,-8(%rbp) #saving end
        pushq   %rbx
        movq    $0,%r8
        movq    $-1,%rbx#(%rbp,%rbx,1)
        #leaq    result  %rdx
        xorq    %rcx,%rcx
PutResultIntoStack:#so we can use data result in all functions
        cmpq    $0x21,%r8
        je      PutResultIntoStackEnd
        movb    result(,%r8,1),%cl
        movb    %cl,-8(%rbp,%rbx,1)
        incq    %r8
        decq    %rbx
        jmp     PutResultIntoStack
PutResultIntoStackEnd:
        leaq    -9(,%rbp,1),%rdx
        xorq    %rcx,%rcx
OverRideSubStringWhileOverString:
        movb    (%rdx),%cl#ovverridesubstr in memory
        cmpb    $0x00,%cl
        je      OverRideSubStringReadyWhileEndItr
        cmpb    $0x29,%cl
        je      OverRideSubStringReadyWhileEndItr
        movb    %cl,(%rdi)
        decq    %rdi
        decq    %rdx
        jmp     OverRideSubStringWhileOverString
OverRideSubStringReadyWhileEndItr:
        xorq    %rcx,%rcx
        movq    -8(%rbp),%rdx#we dont need override_string anymore
OverRideSubStringWhileEndItr:
        movb    (%rdx),%cl
        cmpb    $0x00,%cl
        je      OverRideSubStringWhileStart
        movb    %cl,(%rdi)
        decq    %rdx
        decq    %rdi
        jmp     OverRideSubStringWhileEndItr
OverRideSubStringWhileStart:
        cmpq    %rdi,%rdx
        je      OverRideSubStringEnd
        movb    $0x00,(%rdi)
        decq    %rdi
        jmp     OverRideSubStringWhileStart
OverRideSubStringEnd:
        leave
        ret        

        
CallOperatorCalculate:
#char Operator--%rdi  ^  long long left--%rsi  ^  long long  right %rdx    
#we use here %rax
        pushq   %rbp
        movq    %rsp, %rbp 
        movq    %rsi,%rax
        cmpb    $0x2B,%dil#'+'
        je     CallOperatorCalculateOperatorPlus
        cmpb    $0x2D,%dil #'-'
        je      CallOperatorCalculateOperatorMinus
        cmpb    $0x2F,%dil#'/'
        je      CallOperatorCalculateOperatorDivide
        jmp     CallOperatorCalculateOperatorMulti
        
CallOperatorCalculateOperatorPlus:
        addq    %rdx,%rax
        jmp     CallOperatorCalculateEnd  
CallOperatorCalculateOperatorMinus:
        subq    %rdx,%rax
        jmp     CallOperatorCalculateEnd
CallOperatorCalculateOperatorDivide:
        movq    %rdx,%rdi
        xorq    %rdx,%rdx
        cqo
        idiv    %rdi
        jmp     CallOperatorCalculateEnd  
CallOperatorCalculateOperatorMulti:
        imul    %rdx,%rax
        jmp     CallOperatorCalculateEnd       
CallOperatorCalculateEnd:
        leave
        ret        
        
#CHECKED IT WORKS I THINK
#time now 3:19am been doing debugging for the last 2.5
DecipherNumber:#Could make problems
#char * str --%rdi   ^  functionpointer -- %rsi
#we use %rax,%rcx,%rdx
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $12,%rsp
        movl    $0,-4(%rbp)#local int length
        movq    %rdi,-12(%rbp)#local char* itr
        movq    -12(%rbp),%rax
        xorq    %rcx,%rcx
DecipherNumberWhile:
        movb    (%rax),%cl
        cmpb    $0x29,%cl#')'
        je      DecipherNumberEnding
        cmpb    $0x2B,%cl#'+'
        je      DecipherNumberEnding
        cmpb    $0x2A,%cl#'*'
        je      DecipherNumberEnding
        cmpb    $0x2F,%cl#'/'
        je      DecipherNumberEnding
        cmpq    %rdi,%rax#itr!=str
        jne     DecipherNumberIfItr 
DecipherNumberReturnWhile:
        leaq    result,%rdx
        pushq   %rbx
        movl    -4(%rbp),%ebx
        movb    %cl,(%rdx,%rbx,1)
        popq    %rbx#####CHECK IF PROBLEMS
        incl    -4(%rbp)
        decq    %rax
        jmp     DecipherNumberWhile
DecipherNumberIfItr:
        cmpb    $0x2D,%cl#'-'
        jne     DecipherNumberReturnWhile
        incl    -4(%rbp)
        decq    %rax
        jmp     DecipherNumberEnding
DecipherNumberEnding:
        movq    $20,%rax#we are doing using itr(char*)
        movb    $0x00,result(,%rax,1)
        cmpb    $19,-4(%rbp)
        jg      DecipherNumberEnd
        movl    -4(%rbp),%eax#we are doing using itr(char*)
        movb    $0x00,result(,%eax,1)
DecipherNumberEnd:
        leaq    result,%rdi
        call    *%rsi
        leave
        ret        
        
#WOOOOOOOOOOOOOOORKS#WOOOOOOOOOOOOOOORKS#WOOOOOOOOOOOOOOORKS               
TurnToString:
#   long long num %rdi
#we use %rax,%rdx,%rsi
#0xF000000000000000
#0x7FFFFFFFFFFFFFFF
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $40,%rsp
        movl    $0 ,-4(%rbp)#itr
        movq    $0,-12(%rbp)#num1
        movq    $0,-20(%rbp)#digits
        movq    $1,-28(%rbp)#tmp_num
        movq    $1,-36(%rbp)#ten
        movl    $0,-40(%rbp)#digit
        pushq   %rdi
        xorq    %r10,%r10
        leaq    result,%rdi
EmptyResult:
        cmpq    $21,%r10
        je      EndEmpty
        movb    $0x00,(%rdi,%r10,1)
        incq    %r10
        jmp     EmptyResult
EndEmpty:        
        popq    %rdi
        pushq   %rdi
        movq    $0x8000000000000000,%rax
        andq    %rax,%rdi
        cmpq    %rax,%rdi
        je      NumberIsNegative
        popq    %rdi
        cmp     $0,%rdi
        je      NumberIsZero
        jmp     NumberIsNotNegative
NumberIsZero:
        movb    $0x30,%al
        movb    %al,(result)
        jmp     TurnToStringEnd
NumberIsNegative: 
        popq    %rdi       
        subq    %rdi,-12(%rbp)
        movb    $0x2D,%al
        movb    %al,(result)
        incl    -4(%rbp)
        jmp     TurnToStringReadyWhile
NumberIsNotNegative:
        movq    %rdi,-12(%rbp)
TurnToStringReadyWhile:
        movq    -12(%rbp),%rdi
        #we have not used %rax,%rdx and %rdi is saved already in memory
        call    NumberOfDigits
        #save the result of function into digits
        movq %rax,-20(%rbp)
TurnToStringUpperWhile:
        cmpq    $0,-20(%rbp)
        je      TurnToStringEnd
        #Boot numbers
        movq    $1,-28(%rbp)#tmp_num=1
        movq    $1,-36(%rbp)#ten=1
TurnToStringInnerWhile:
        movq    -20(%rbp),%rdx#digits
        cmpq    -36(%rbp),%rdx#compare ten to digits
        je     TurnToStringAfterInnerWhile
        movq    -28(%rbp),%rax
        movq    $10,%rsi
        mul     %rsi
        movq    %rax,-28(%rbp)
        movq    -20(%rbp),%rdx#reboot %rdx to digits
        incq    -36(%rbp)
        jmp     TurnToStringInnerWhile
TurnToStringAfterInnerWhile:
        #take num1 put it into %rax
        movq    -12(%rbp),%rax
        #make %rdx zero
        xorq    %rdx,%rdx
        divq    -28(%rbp) #num1/tmp_num
        xorq    %rdx,%rdx
        #we can change tmp_num because we already have num1/tmp_num in %rax
        movq    $10,-28(%rbp)
        divq    -28(%rbp)
        movl    %edx,-40(%rbp)#digit=(num1/tmp_num)%10
        addl    $0x30,%edx#('0'+digit)
        movl    -4(%rbp),%esi
        movb    %dl,result(,%esi,1)
        incl    -4(%rbp)
        decq    -20(%rbp)
        jmp     TurnToStringUpperWhile
TurnToStringEnd:
        leave
        ret            
#WOOOOOOOOOOOOOOORKS#WOOOOOOOOOOOOOOORKS#WOOOOOOOOOOOOOOORKS        

                 
                                  
                                                   
                                                                    
                                                                                     
Calculate:
#function pointer in --%rdi   ^  char* start ---%rsi        ^     char*  --%rdx
#we use %rax,%rdx,%rcx,%r8,%r9
        pushq   %rbp
        movq    %rsp,%rbp    
        #8*3(save function variables)
        #8*7(save local first 7 variables)
        #4+8(first 4 is minus count,second char* itr)
        subq    $92,%rsp
        movq    %rdi,-8(%rbp)#function pointer
        movq    %rsi,-16(%rbp)#char * start
        movq    %rdx,-24(%rbp)#char* end
        movq    $0,-32(%rbp)#char* left_opr = NULL
        movq    $0,-40(%rbp)#char* right_opr = NULL
        movq    $0,-48(%rbp)#char* opr = NULL
        movq    $0,-56(%rbp)#left=0
        movq    $0,-64(%rbp)#right=0
        movq    $0,-72(%rbp)#res=0
        movq    $0,-76(%rbp)#minus_count=0
        movq    $0,-84(%rbp)#char* itr
        movq    $0,-92(%rbp)#char* first_opr
       
 
CalculateWhileDivide:
        movq    -16(%rbp),%rdi#we boot %rdi as start
        movq    -24(%rbp),%rsi#we boot %rsi as end
        call    FindDivideOperator       
        movq    %rax,-48(%rbp)#opr=FindDivideOperator(start, end)
        cmpq    -24(%rbp),%rax#Stop While
        je      CalculateWhileMulti
        movq    -16(%rbp),%rdi
        movq    -24(%rbp),%rsi
        call    FindMultiOperator 
        cmpq    -48(%rbp),%rax
        jg      CalculateWhileMulti
        movq    -16(%rbp),%rdi#we boot %rdi as start
        movq    -48(%rbp),%rsi#we boot %rsi as opr
        call    FindLeftOperator
        movq    %rax,-32(%rbp)#left_opr=FindLeftOperator(start, opr)
        movq    -48(%rbp),%rdi#opr=%rdi
        decq    %rdi
        decq    %rdi#opr=opr+2
        call    FindRightOperator
        movq    %rax,-40(%rbp)#right_opr=FindRightOperator(opr+2)
        jmp     If        
CalculateWhileDivideBackIf:
        movq    -32(%rbp),%rdi#%rdi=left_opr
        movq    -8(%rbp),%rsi#%rsi=function pointer
        call    DecipherNumber
        movq    %rax,-56(%rbp)#left=ret of DecipherNumber
        movq    -48(%rbp),%rdi#ready %rdi as opr for next function
        decq    %rdi#opr=opr+1
        movq    -8(%rbp),%rsi#ready %rsi as Function pointer
        call    DecipherNumber
        movq    %rax,-64(%rbp)#right=%rax
        xorq    %rcx,%rcx
        movq    -48(%rbp),%rcx#%rcx=opr
        xorq    %rdi,%rdi
        movb    (%rcx),%dil#*opr= %dil
        movq    -56(%rbp),%rsi#%rsi=left
        movq    -64(%rbp),%rdx#%rdx=right
        call    CallOperatorCalculate
        movq    %rax,-72(%rbp)#res=CallOperatorCall(*opr,left,right)
        movq    -72(%rbp),%rdi#start %rdi to res
        call    TurnToString
        movq    -32(%rbp),%rdi#ready %rdi as left_opr
        movq    -40(%rbp),%rsi#ready %rsi as right_opr
        call    OverRideSubString#write the string into the original
        movq    -16(%rbp),%rdi#ready start as %rdi
        #find the new next closing again after losing it in the function
        call    FindFirstClosing
        movq    %rax,-24(%rbp)#update the new end
        jmp     CalculateWhileDivide #redo while
        
        
        
CalculateWhileMulti:
        movq    -16(%rbp),%rdi
        movq    -24(%rbp),%rsi
        call    FindMultiOperator
        movq    %rax,-48(%rbp)#opr=FindDivideOperator(start, end)
        cmpq    -24(%rbp),%rax
        je      CalculateReadyWhileMinus
        movq    -16(%rbp),%rdi#we boot %rdi as start
        movq    -24(%rbp),%rsi#we boot %rsi as end
        call    FindDivideOperator
        cmpq    -48(%rbp),%rax
        jg      CalculateWhileDivide   
        movq    -16(%rbp),%rdi
        movq    -48(%rbp),%rsi
        call    FindLeftOperator
        movq    %rax,-32(%rbp)#left_opr=FindLeftOperator(start, opr)
        movq    -48(%rbp),%rdi
        decq    %rdi
        decq    %rdi
        call    FindRightOperator
        movq    %rax,-40(%rbp)#right_opr=FindRightOperator(opr+2)
        jmp     If        
CalculateWhileMultiBackIf:
        movq    -32(%rbp),%rdi
        movq    -8(%rbp),%rsi
        call    DecipherNumber
        movq    %rax,-56(%rbp)
        movq    -48(%rbp),%rdi
        decq    %rdi
        movq    -8(%rbp),%rsi
        call    DecipherNumber
        movq    %rax,-64(%rbp)
        xorq    %rcx,%rcx
        movq    -48(%rbp),%rcx
        xorq    %rdi,%rdi
        movb    (%rcx),%dil
        movq    -56(%rbp),%rsi
        movq    -64(%rbp),%rdx
        call    CallOperatorCalculate
        movq    %rax,-72(%rbp)
        movq    -72(%rbp),%rdi
        call    TurnToString
        movq    -32(%rbp),%rdi
        movq    -40(%rbp),%rsi
        call    OverRideSubString
        movq    -16(%rbp),%rdi
        call    FindFirstClosing
        movq    %rax,-24(%rbp)
        jmp     CalculateWhileMulti 
        
          
              
CalculateReadyWhileMinus:
        movq    -16(%rbp),%rdi#we boot %rdi as start
        movq    -24(%rbp),%rsi#we boot %rsi as end
        call    FindDivideOperator
        cmpq    -24(%rbp),%rax
        jne     CalculateWhileDivide 
        movq    -16(%rbp),%rdi
        movq    -24(%rbp),%rsi
        call    CountNumberOfMinus
        movl    %eax,-76(%rbp)
        movq    -16(%rbp),%rdi
        movq    %rdi,-84(%rbp)
CalculateWhileMinus:
        cmpl    $0,-76(%rbp)#minus_cout=0
        je      CalculateWhilePlus
        movq    -84(%rbp),%rdi
        movq    -24(%rbp),%rsi
        call    FindMinusOperator
        cmpq    %rax,-24(%rbp)
        je      CalculateWhilePlus
        movq    %rax,-48(%rbp)#%rax=opr
        incq    %rax
        xorq    %rcx,%rcx
        movb    (%rax),%cl
        cmpb    $0x2D,%cl
        je      ProcessMinusIf
        cmpb    $0x28,%cl
        je      ProcessMinusIf
        cmpb    $0x2B,%cl
        je      ProcessMinusIf
        movq    -16(%rbp),%rdi
        movq    -48(%rbp),%rsi
        call    FindLeftOperator
        movq    %rax,-32(%rbp)#left_opr=FindLeftOperator(start, opr)
        movq    -48(%rbp),%rdi
        decq    %rdi
        decq    %rdi
        call    FindRightOperator
        movq    %rax,-40(%rbp)#right_opr=FindRightOperator(opr+2)
        jmp     If        
CalculateWhileMinusBackIf:
        movq    -32(%rbp),%rdi
        movq    -8(%rbp),%rsi
        call    DecipherNumber
        movq    %rax,-56(%rbp)
        movq    -48(%rbp),%rdi
        decq    %rdi
        movq    -8(%rbp),%rsi
        call    DecipherNumber
        movq    %rax,-64(%rbp)
        xorq    %rcx,%rcx
        movq    -48(%rbp),%rcx
        xorq    %rdi,%rdi
        movb    (%rcx),%dil
        movq    -56(%rbp),%rsi
        movq    -64(%rbp),%rdx
        call    CallOperatorCalculate
        movq    %rax,-72(%rbp)
        movq    -72(%rbp),%rdi
        call    TurnToString
        movq    -32(%rbp),%rdi
        movq    -40(%rbp),%rsi
        call    OverRideSubString
        movq    -16(%rbp),%rdi
        call    FindFirstClosing
        movq    %rax,-24(%rbp)
        decl    -76(%rbp)
        jmp     CalculateWhileMinus        

                
ProcessMinusIf:
        decl    -76(%rbp)
        decq    %rax
        decq    %rax
        movq    %rax,-84(%rbp)
        jmp     CalculateWhileMinus
        
                
CalculateWhilePlus:
        movq    -16(%rbp),%rdi#we boot %rdi as start
        movq    -24(%rbp),%rsi#we boot %rsi as end
        call    FindPlusOperator
        movq    %rax,-48(%rbp)#opr=FindDivideOperator(start, end)
        cmpq    -24(%rbp),%rax#Stop While
        je      CalculateEnd
        movq    -16(%rbp),%rdi#we boot %rdi as start
        movq    -48(%rbp),%rsi#we boot %rsi as opr
        call    FindLeftOperator
        movq    %rax,-32(%rbp)#left_opr=FindLeftOperator(start, opr)
        movq    -48(%rbp),%rdi#opr=%rdi
        decq    %rdi
        decq    %rdi#opr=opr+2
        call    FindRightOperator
        movq    %rax,-40(%rbp)#right_opr=FindRightOperator(opr+2)
        jmp     If        
CalculateWhilePlusBackIf:
        movq    -32(%rbp),%rdi#%rdi=left_opr
        movq    -8(%rbp),%rsi#%rsi=function pointer
        call    DecipherNumber
        movq    %rax,-56(%rbp)#left=ret of DecipherNumber
        movq    -48(%rbp),%rdi#ready %rdi as opr for next function
        decq    %rdi#opr=opr+1
        movq    -8(%rbp),%rsi#ready %rsi as Function pointer
        call    DecipherNumber
        movq    %rax,-64(%rbp)#right=%rax
        xorq    %rcx,%rcx
        movq    -48(%rbp),%rcx#%rcx=opr
        xorq    %rdi,%rdi
        movb    (%rcx),%dil#*opr= %dil
        movq    -56(%rbp),%rsi#%rsi=left
        movq    -64(%rbp),%rdx#%rdx=right
        call    CallOperatorCalculate
        movq    %rax,-72(%rbp)#res=CallOperatorCall(*opr,left,right)
        movq    -72(%rbp),%rdi#ready %rdi as res
        call    TurnToString
        movq    -32(%rbp),%rdi#ready %rdi as left_opr
        movq    -40(%rbp),%rsi#ready %rsi as right_opr
        call    OverRideSubString#write the string into the original
        movq    -16(%rbp),%rdi#ready start as %rdi
        #find the new next closing again after losing it in the function
        call    FindFirstClosing
        movq    %rax,-24(%rbp)#update the new end
        jmp     CalculateWhilePlus #redo while 
CalculateEnd:
        leave
        ret                                                                                                                                
If:#/*the minus is not unary to decipher the number right*/
        movq    -32(%rbp),%rdx
        xorq    %rcx,%rcx
        movb    (%rdx),%cl#*(left_opr)
        xorq    %r8,%r8
        incq    %rdx
        movb    (%rdx),%r8b#*(left_opr-1)
        cmpb    $0x2D,%cl#left_opr!='-'
        jne     IncreaseLeft_opr
        cmpb    $0x2D,%r8b#left_opr-1=='-'
        je      DecideWhereToJmpBack
        cmpb    $0x2B,%r8b#left_opr-1=='+'
        je      DecideWhereToJmpBack
        cmpb    $0x2A,%r8b#left_opr-1=='*'
        je      DecideWhereToJmpBack
        cmpb    $0x2F,%r8b#left_opr-1=='/'
        je      DecideWhereToJmpBack
        cmpb    $0x28,%r8b#left_opr-1=='('
        je      DecideWhereToJmpBack
IncreaseLeft_opr:  
        decq    -32(%rbp)#left_opr++
        jmp     DecideWhereToJmpBack
DecideWhereToJmpBack:
        movq    -48(%rbp),%rdx#%rdx=opr
        xorq    %rcx,%rcx
        movb    (%rdx),%cl#%cl=*opr
        cmpb    $0x2F,%cl#*opr=='/'
        je      CalculateWhileDivideBackIf
        cmpb    $0x2A,%cl#*opr=='*'
        je      CalculateWhileMultiBackIf
        cmpb    $0x2B,%cl#*opr=='+'
        je      CalculateWhilePlusBackIf
        cmpb    $0x2D,%cl#*opr=='-'
        je      CalculateWhileMinusBackIf
        
        
        
Evaluate:
#function pointer   --  %rdi   ^ char * str --  %rsi,%edx--parn_num
#we use here %rax,%rcx,%r9,%rsi,%rdi
        pushq   %rbp
        movq    %rsp,%rbp
        #we could need to refresh the result into zeros
        subq    $44,%rsp
        movq    %rdi,-8(%rbp)#function pointer
        movq    %rsi,-16(%rbp)#char * str
        movq    $0,-24(%rbp)#char* open=NULL
        movq    $0,-32(%rbp)#char* close = NULL
        movq    $0,-40(%rbp)#tmp_open=NULL
        movl    %edx,-44(%rbp)#pran_num
EvaluateWhile:
        cmpl    $0,-44(%rbp)
        jle     EvaluateEnd 
        pushq   %rdi
        xorq    %r10,%r10
        leaq    result,%rdi
EEmptyResult:
        cmpq    $21,%r10
        je      EEndEmpty
        movb    $0x00,(%rdi,%r10,1)
        incq    %r10
        jmp     EEmptyResult
EEndEmpty:        
        popq    %rdi
        movq    -16(%rbp),%rdi
        movl    -44(%rbp),%esi
        call    FindLastOpening
        movq    %rax,-24(%rbp)
        movq    -24(%rbp),%rdi
        call    FindFirstClosing    
        movq    %rax,-32(%rbp)
        movq    -8(%rbp),%rdi#function pointer
        movq    -24(%rbp),%rsi#open
        movq    -32(%rbp),%rdx#close
        call    Calculate
        movq    -24(%rbp),%rdi
        call    FindFirstClosing    
        movq    %rax,-32(%rbp)#close_in memory
        xorq    %rcx,%rcx
        movb    (result),%cl
        cmpb    $0x00,%cl
        je      EvaluateWhileIf    
        jmp     WhileAfterOutsideIf
                 
EvaluateWhileIf:#if(result[0]=='\0')
        movq    -24(%rbp),%rax#open in raxx
        movq    %rax,-40(%rbp)#tmp_open=open
        movq    -40(%rbp),%rax
        xorq    %rcx,%rcx
        movq    $0,%rcx
        subq    $1,%rax#tmp_open=tmp_open+1
        movq    %rax,-40(%rbp)
ForWhileIf:#for(int i=0;i<20;i++)
        movq    -40(%rbp),%rax
        cmpq    $20,%rcx
        je      ForWhileIfEnd
        xorq    %r9,%r9
        subq    %rcx,%rax#tmp_open=tmp_open+i
        movb    (%rax),%r9b#%r9b=*tmp_open+i+1
        cmpb    $0x29,%r9b
        jne     ForWhileIfInsideIfEnd
        movb    $0x00,result(,%rcx,1)#result[i]='\0'
        jmp     ForWhileIfEnd
ForWhileIfInsideIfEnd:
        movb    %r9b,result(,%rcx,1)
        addq    $1,%rcx
        jmp     ForWhileIf
                                                
ForWhileIfEnd:
        xorq    %rcx,%rcx
        movq    $20,%rcx
        movb    $0x00,result(,%rcx,1)
        movq    -24(%rbp),%rdi#open
        movq    -32(%rbp),%rsi#close
        decq    %rsi
        call    OverRideSubString
        decl    -44(%rbp)
        jmp     EvaluateWhile    
WhileAfterOutsideIf:
        movq    -24(%rbp),%rdi
        movq    -32(%rbp),%rsi
        decq    %rsi 
        call    OverRideSubString 
        decl    -44(%rbp)
        jmp     EvaluateWhile                                                                                                               
EvaluateEnd:
        leave
        ret        
             