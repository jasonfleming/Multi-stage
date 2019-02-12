!
! This program reads Multistage products and calculate the mean and
! standard deviation of each, and generate three distinct files 
! 1)Mean 2)Mean+std 3)Mean-std
!
! Ex:
!    ./hydro-stat.x fort.63_GEFS  fort.63_GEFSmean  fort.63_SREFmean 
!    output:
!           fort_mean.63 fort_meanPstd.63 fort_meanMstd.63
!
!
! This program is part of Ensemble-Multistage developed by Taeb and
! Weaver.
!
! Author: Peyman Taeb, Feb 2019
! --------------------------------------------------------------------
  program hydroStat
  implicit none
  
  ! Variable decleration
  character(len=85)              :: header1
  character(len=52)              :: Junk1, Junk2
  character(len=37)              :: time_header
  character(len=15)              :: arg
  character(len=15),allocatable,dimension(:,:)  ::  inputs
  character(len=37),allocatable,dimension(:,:)  ::  temp_time_header

  real,allocatable,dimension(:,:)               ::  temp_q, temp_q1, temp_q2
  real,allocatable,dimension(:,:)               ::  mean,   mean1,   mean2
  real,allocatable,dimension(:,:)               ::  std,    std1,    std2   
  real,allocatable,dimension(:,:)               ::  minn,   minn1,   minn2
  real,allocatable,dimension(:,:)               ::  maxx,   maxx1,   maxx2

  real                           :: q       ! Scalar quantity
  real                           :: q1,q2   ! Components of a vector quantity
 
  integer                        :: col     ! number of columns of the inputs 
  integer                        :: NOI     ! Number Of Inputs
  integer                        :: ts      ! Time step
  integer                        :: k,i,j   ! Some loop stuff
  integer                        :: nodes   ! This is also some loop stuf
  integer                        :: NN, OTS ! Number of Node. Ouput Time Step
  integer                        :: n       !node number

  ! Reading the files to process
  ! GEt the number of command-line arguments
  ! NOI : number of inputs
  NOI = iargc()  

  ! Allocate array that will contain arguemnts
  allocate(inputs(NOI,1))
  do k =1, NOI
     call getarg(k,arg)
     inputs(k,1)=arg
  enddo

  ! Loop inputs
  do k=1,NOI
     
     !open the file
     open(unit=91,file=inputs(k,1))
    
     ! Notifying
     write(*,*) ""
     write(*,*) "INFO: Reading file: ", inputs(k,1) 

     !read the header
     read(91,'(A85)') header1
     
     !read the second header and getting the number of output time steps and
     !node numbers
78   format(i11,i11,A30,i1,A30)
     read(91,78) OTS, NN, Junk1, col, Junk2


     ! Allocate arrays containing input values and time header before getting
     ! into the related loops. We should do it once for the temp_time_header
     ! and temp_q, otherwise we re-allocate these two for every input, probably
     ! leadeing to getting error when compiling
     if ( k .eq. 1) then
        allocate(temp_time_header(OTS,1))
        allocate(temp_q(NN,NOI))         ! Scaler quantity
        allocate(temp_q1(NN,NOI))        ! U component of the vector quantity
        allocate(temp_q2(NN,NOI))        ! V component of the vector quantity
     endif
 
     ! Loop time steps
     do ts=1,OTS
        read(91,'(A37)') time_header      

        ! We keep time headers and later write them into 3 outputs
        ! We do it once of Course!
        if ( k .eq. 1) then  
           temp_time_header(ts,1)=time_header
        endif

        ! Loop nodes 
        do nodes=1,NN

           ! Determine the output is scalar or vector
           ! if Col=1 => Scalar, if Col=2 => Vector
           if ( col .eq. 1) then

79            format(i10,1PE22.10E3)
              read(91,79) n, q
              temp_q(nodes,k)=q
           
           elseif ( col .eq. 2) then
 
80            format(i10,1PE22.10E3,1PE22.10E3)
              read(91,80) n, q1, q2
              temp_q1(nodes,k)=q1
              temp_q2(nodes,k)=q2

           endif        

        ! Ends loop nodes
        enddo

     ! End loop time step
     enddo
 
  ! End loop inputs
  enddo

  ! Notifying
  write(*,*) 
  write(*,*) 'INFO: Finished reading files'
  ! Writing temp files to make sure everything is right (development)
  ! All quantity together in one file
  open(unit=99,position="append", action="write")

  write(99,'(A85)') header1  
  write(99,78) OTS, NN, Junk1, col, Junk2

!
81 format(1PE22.10E3,1PE22.10E3,1PE22.10E3,1PE22.10E3, &
          1PE22.10E3,1PE22.10E3,1PE22.10E3)

  do k=1,OTS
    
     ! Notifying
     write(*,*)
     write(*,*) 'INFO: writing time step ', k, 'on 99 (development)'

     write(99,'(A37)') temp_time_header(k,1)
     write(99,81) ((temp_q(i,j),i=1,NN),j=1,NOI)

  enddo

  ! Calculating mean, std, max, min
  ! (1) Mean ------------------------------------------------------------------
                                             
  if ( col .eq. 1 ) then      ! Scalar -- #3

     ! Loop through the columns in a row. Each column is one model run
     do i=1,NN*OTS    ! The total rows of temp_q(##)
        summ=0
        do j=1,NOI    ! there are NOI number of model predictions in each row
           summ = summ + temp_q(i,j)
        enddo
        mean(i,1)=summ/NOI
     enddo

  elseif ( col .eq. 2) then  ! Vector -- #4
     
     ! Loop through the columns in a row. Each column is one model run
     do i=1,NN*OTS    ! The total rows of temp_q(##)
        summ1=0
        summ2=0
        do j=1,NOI    ! there are NOI number of model predictions in each row
           summ1 = summ1 + temp_q1(i,j)
           summ2 = summ2 + temp_q2(i,j)
        enddo
        mean1(i,1)=summ1/NOI
        mean2(i,1)=summ2/NOI        
     enddo

  ! (1) std ------------------------------------------------------------------

  if ( col .eq. 1 ) then      ! Scalar -- #3

     ! Loop through the columns in a row. Each column is one model run
     do i=1,NN*OTS    ! The total rows of temp_q(##)
        stdd=0
        do j=1,NOI    ! there are NOI number of model predictions in each row
           stdd = stdd + ( temp_q(i,j) - mean(i,1))**2
        enddo
        std(i,1)=sqrt(std/(NOI-1))
     enddo

  elseif ( col .eq. 2) then  ! Vector -- #4

     ! Loop through the columns in a row. Each column is one model run
     do i=1,NN*OTS    ! The total rows of temp_q(##)
        summ1=0
        summ2=0
        do j=1,NOI    ! there are NOI number of model predictions in each row
           summ1 = summ1 + temp_q1(i,j)
           summ2 = summ2 + temp_q2(i,j)
        enddo
        mean1(i,1)=summ1/NOI
        mean2(i,1)=summ2/NOI
     enddo
  endif

  end program

