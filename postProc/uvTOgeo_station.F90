!
! This program reads U V files of station files such as fort.62 or fort.72
! and return geographical directions
! 0 is north, 90 is east, 180 is south, and 270 is west.
!
! A component of Multistage developed by Peyman Taeb & Robert J Weaver
! Author: Peyman Taeb Feb, 2019
!
! Note:
!      Fortran can't distinguish between -u/v (quarter 2, Q2) and 
!      u/-v (Q 4). Similarly, it can't distinguish u/v (Q1) and
!      -u/-v (Q3). FORTRAN calculates between -pi to pi, not 0-2pi
!      "IF statements" account for different quarters.
!      It gets tricky when the vector falls in Q2 and Q3. 
!
!      The input file is read as an argument
!      EX:
!         ./uvTOgeo_station.x fort.72_transpose.txt
!      Output:
!         fort.72_dir_transpose.txt
!
! Shortcoming
!      This code can't recognize the number of u/v pairs
!      In the initial development, I tried to make it flexible 
!      However, I couldn't! At the moment, I have 2 stations with
!      4 columns (U1 V1 U2 V2)
!      The code has to be adjusted if stations are added or removed
! --------------------------------------------------------------------
  !
  program uvTOgeoStation
  implicit none
  
  ! Variable decleration
  character(len=200)       :: aline
  character(len=21)        :: InpFile
  character(len=85)        :: header1
  character(len=65)        :: Junk
  character(len=21)        :: arg
  real, parameter          :: PI = 3.1415926       ! some constants
  real                     :: dir,dir1, dir2
  real                     :: u,v,u1,v1,u2,v2
  integer                  :: io
  integer                  :: k
  integer                  :: total,st_no
  integer                  :: i
  ! Reading the argument
  do k =1, iargc()
     call getarg(k,arg)
        if ( k.eq.1 ) then
            read (arg,'(A21)') InpFile
        endif
  enddo
  ! open file to read
  open(unit=92,file=InpFile)

  ! open file to write
  open(unit=93,file="fort.72_dir_transpose.txt")

78  format(i11,i11,A58)
  
  ! reading the 1st two lines
  read(92,'(A85)') header1
  write(93,'(A85)') header1

  read(92,'(A85)') header1
  write(93,'(A85)') header1

!=============================================================================
! 
! Under development
! Goal: The code detects how many pairs of u/v exist in fort.##_transpose.txt
!       Not completed yet

  ! Getting the number of element in the line to
  ! figure out the number of stations
  ! Requiring reading the entire file and call the fucntion nitems
! io = 0.0
! do
!   read(92,'(A200)',IOSTAT=io) aline
!
!   if ( io.eq.0 ) then
!      total=nitems(aline)
!   else
!      go to 20
!   endif
! enddo
!
!20 continue 

  ! number of stations => total - 3(date time zone) / 2 (2 components)
  ! This parameter is not used in this version
  ! Updates need to make for accounting for input with different # of columns
!  st_no=total-3

  ! Close and open the file again
!  close(92)
  ! open file to read
 ! open(unit=92,file=InpFile)

  ! reading the 1st two lines again
!  read(92,'(A85)') header1
!  read(92,'(A85)') header1
!=============================================================================


79 format(A23,4f21.10)

  io = 0.0
  do
    read(92,79,IOSTAT=io) junk, u1,v1,u2,v2

    ! Controling end of file
    if ( io.eq.0 ) then

    ! Go through 2 sets of columns
    do i=1,2
       
       ! assigning 
       if ( i.eq.1 ) then
          u=u1
          v=v1
       elseif ( i.eq.2) then
          u=u2
          v=v2
       endif

       if ( u.ne. -9.9999000000E+004 ) then
          ! Quarter 1
          if ( u.ge.0 .and. v.ge.0 ) then
             dir=(270-atan(v/u)*180/pi)
          ! Quarter 2
          elseif ( u.lt.0 .and. v.ge.0 ) then
             dir=(180+atan(v/u)*180/pi)
          ! Quarter 3
          elseif ( u.lt.0 .and. v.lt.0 ) then
             dir=(90-atan(v/u)*180/pi)
          ! Quarter 4
          elseif ( u.gt.0 .and. v.lt.0 ) then
             dir=(270-atan(v/u)*180/pi)
          endif
       else
          dir=-9.9999000000E+004
       endif
   
       ! assigning
       if ( i.eq.1 ) then
          dir1=dir
       elseif ( i.eq.2 ) then
          dir2=dir
       endif
   
    !endo i=1,2
    enddo
 
    ! io
    else 
       go to 21
    endif

    write(93,'(A23,2f21.10)') junk, dir1, dir2
 enddo

21 continue
!
!==========================================================
!
!              FUNCTION to read the # of column 
!             to identify the number of station output
!
!==========================================================
    ! number of space-separated items in a line
    contains
    function nitems(line)
    character ::  line*(*)    
    logical   ::  back
    integer   ::  nitems
    integer   ::  length
    
    back = .true.        
    length = len_trim(line)    
    k = index(line(1:length), ' ', back)
    if (k == 0) then
        nitems = 0
        return
    end if    
    
    nitems = 1
    do 
        ! starting with the right most blank space, 
        ! look for the next non-space character down
        ! indicating there is another item in the line
        do
            if (k <= 0) exit
            
            if (line(k:k) == ' ') then
                k = k - 1
                cycle
            else
                nitems = nitems + 1
                exit
            end if
            
        end do
        
        ! once a non-space character is found,
        ! skip all adjacent non-space character
        do
            if ( k<=0 ) exit
            
            if (line(k:k) /= ' ') then
                k = k - 1
                cycle
            end if
            
            exit
            
        end do
        
        if (k <= 0) exit
            
    end do
  end function nitems 
  !                      
  !                      FUNCTION ENDS
  ! -------------------------------------------------------------
  end program 
