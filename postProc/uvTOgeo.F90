!
! This program reads U V files such as fort.64 or fort.74
! and return geographical directions
! 0 is north, 90 is east, 180 is south, and 270 is west.
!
! A component of Multistage developed by Peyman Taeb & Robert J Weaver
! Author: Peyman Taeb Feb, 2019
! 
! --------------------------------------------------------------------
  !
  program uvTOgeo
  implicit none
  
  ! Variable decleration
  character(len=85)        :: header1
  character(len=52)        :: Junk
  character(len=37)        :: TS ! Time Step
  real, parameter          :: PI = 3.1415926       ! some constants
  real                     :: dir
  real                     :: u,v
  integer                  :: NN, OTS ! Output Time Step
  integer                  :: n !node
  integer                  :: i,j

  ! open file to read
  open(unit=92,file="InpFile")

  ! open file to write
  open(unit=93,file="OutFile")

78  format(i11,i11,A58)
  
  ! reading 1st line; main header & write new file
  read(92,'(A85)') header1
  write(93,'(A85)') header1

  ! reading the second header and getting number
  ! of output time step and node numbers & write new file
  read(92,78) OTS, NN, Junk
  write(93,78) OTS, NN, Junk

  ! Go through time steps
  do i=1,OTS
     read(92,'(A37)') TS
     write(93,'(A37)') TS
     ! Go through nodes
     do j=1,NN
        read(92,'(i10,1PE22.10E3,1PE22.10E3)') n, u, v
        if ( dir.ne. -9.9999000000E+004 ) then
           ! Sector 1 
           if ( u.ge.0 .and. v.ge.0 ) then
              dir=(270-atan(u/v)*180/pi)
           ! Sector 2
           elseif ( u.lt.0 .and. v.ge.0 ) then
              dir=(180+atan(u/v)*180/pi)
           ! Sector 3
           elseif ( u.lt.0 .and. v.lt.0 ) then
              dir=(90-atan(u/v)*180/pi)
           elseif ( u.gt.0 .and. v.lt.0 ) then
              dir=(270-atan(u/v)*180/pi)
           endif
        else
           dir=-9.9999000000E+004
        endif
        write(93,'(i10,1PE22.10E3)') n, dir
     enddo
  write(*,*) "progress: Time step ", i,"out of ",OTS
  enddo
!
  end program 
