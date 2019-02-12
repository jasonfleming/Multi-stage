!
! Author
! Peyman Taeb Nov 2018
!
! Program description:
! Vist https://research.fit.edu/wave-data/real-time-data/          
! Click on water level. Look at the plot legend; SISPNJ, Demeaned ADCP
! I have access to SISPNJ. We know, from model simulations and our
! knowledge, that water level of demeaned is correct. This seems to be
! the moving-minimum average. This code calculates the moving-minimum
! filter of this data downloaded by cprg-WL-download.sh
! + demean
!
! Usage:
!      ./moving.minimum.WL.x
!
!-----------------------------------------------------------------------
  program moving_minimum_WL
  implicit none

  integer                            :: b
  integer                            :: io
  integer                            :: i
  integer                            :: j
  integer                            :: k
  integer                            :: cntr
  character(len=20)                  :: junk1, junk2, junk3, junk4
  real, dimension(:,:), allocatable  :: wl_raw
  real, dimension(:,:), allocatable  :: wl_prcsd
  real, dimension(:,:), allocatable  :: ave_wl_raw
  real                               :: wl
  real                               :: ave
  real                               :: diff
!-----------------------------------------------------------------------
  write(*,*) " Program description: "
  write(*,*) "  Vist https://research.fit.edu/wave-data/real-time-data/"
  write(*,*) "  Click on water level. Look at the plot legend; SISPNJ, Demeaned ADCP"
  write(*,*) "  I have access to SISPNJ. We know, from model simulations and our"
  write(*,*) "  knowledge, that water level of demeaned is correct. This seems to be"
  write(*,*) "  the moving-minimum average. This code calculates the moving-minimum"
  write(*,*) "  filter of this data downloaded by cprg-WL-download.sh"
!-----------------------------------------------------------------------
  
  ! Open the raw data file to read 
  open(unit=18,file="obs-cprg")
  
  ! Getting the size of the file
  io=0.0
  cntr=0
  do
  if  ( io.eq.0 ) then
      cntr=cntr+1
      read(18,*,iostat=io) junk1, junk2, junk3, junk4
  else
      go to 13
  endif
  enddo
13 continue
  close(unit=18)
  cntr=cntr-1
  
  ! Allocate the matrix contaning raw data
  allocate(wl_raw(cntr,1))
  allocate(wl_prcsd(cntr,1))
  allocate(ave_wl_raw(cntr,1))

  ! Open the raw data file to allocate
  open(unit=18,file="obs-cprg")
  do k=1,cntr
     read(18,*,iostat=io) junk1, junk2, junk3, wl
     wl_raw(k,1) = wl
  enddo
  close(unit=18)

  ! Calculating the average and demeanin
  ave=sum(wl_raw(1:cntr,1))/cntr
  write(*,*) "INFO: the average is ",  ave, " meter"  
  do i=1,cntr
     ave_wl_raw(i,1) = wl_raw(i,1) - ave
  enddo

  ! Applying moving-minimum filter
  b=8     ! Sample number to get filter at each data point; 4 sample/hour
  do i=1,b/2
     wl_prcsd(i,1)=-99999
  enddo

  do i=cntr-b/2+1,cntr
     wl_prcsd(i,1)=-99999
  enddo

  do i=b/2+1,cntr-b/2
     wl_prcsd(i,1)=0  
     do j = 1,b/2-1
        ! Long line split into two
        wl_prcsd(i,1) = wl_prcsd(i,1) + (1.0/b)*(ave_wl_raw(i-j+1,1) + ave_wl_raw(i+j-1,1))
        !diff=abs(ave_wl_raw(i,1)-ave_wl_raw(i-1,1))
        !wl_prcsd(i,1) = wl_prcsd(i,1) - diff
     enddo
  enddo

  ! Writing to file
  do i=1,cntr
     write(199,*) wl_prcsd(i,1)
  enddo
  
  end program
