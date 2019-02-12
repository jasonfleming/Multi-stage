!
!
!
! --------------------------------------------------------------------------
! Copyright(C) 2018 Florida Institute of Technology
! Copyright(C) 2018 Peyman Taeb & Robert J Weaver
!
! This program is prepared as a part of the Multi-stage tool. 
! The Multi-stage tool is an open-source software available to run, study,
! change, distribute under the terms and conditions of the latest version
! of the GNU General Public License (GPLv3) as published in 2007.
! 
! Although the Multi-stage tool is developed with careful considerations 
! with the aim of usefulness and helpfulness, we do not make any warranty
! express or implied, do not assume any responsibility for the accuracy, 
! completeness, or usefulness of any components and outcomes. 
!
! The terms and conditions of the GPL are available to anybody receiving 
! a copy of the Multi-stage tool. It can be also found in 
! <http://www.gnu.org/licenses/gpl.html>.
!
!--------------------------------------------------------------------------
!
      program bcGen
      implicit none
      ! for reading from fort.61 and writing fort.19
      character(len=100)  ::  line1,line2,Header,InputFile_Elev, arg
      integer             ::  i,j,k, BLNUM, NN, timestep, ttlOpenNode
      real                ::  Elev
      real, dimension(:,:), allocatable :: elevation
      !
      ! 
      ! for reading fort.14 and getting nope and nvdll 
      integer :: ios ! i/o status
      integer :: lineNum ! line number currently being read
      integer :: neta_count, nvel_count
      integer :: nvell_max, nvdll_max
      integer, parameter :: iunit = 14
      character(len=100) :: agrid
      integer :: ne, np, mne, mnp, neta, mneta, nope,mnope, ii, jj, m
      integer, dimension(:), allocatable :: nvdll
      !
      ! for reading fort.14 and getting nope and nvdll ---------------------
      ! initializations
      lineNum = 1
      ! reading the file
      open(unit=14,file="fort.14")
      read(14,fmt=*) agrid
      lineNum = lineNum + 1
      read(14,fmt=*) ne, np
      do k = 1, np
         read(14,fmt=*) i
      enddo
      do k = 1, ne
         read(14,fmt=*) i
      enddo
      !
      allocate(nvdll(np))
      read(14,fmt=*) nope  ! total number of elevation boundaries
      mnope = nope
      read(14,fmt=*) neta  ! total number of nodes on elevation boundaries

      do k = 1, nope
         read(14,fmt=*) nvdll(k) ! number of nodes on the kth elevation boundary segment
         do j = 1, nvdll(k)
            read(14,fmt=*)
         enddo
      enddo
! ---------------------------------------------------
!
!    Reading fort.61 and writing fort.19
!   
! ---------------------------------------------------
!  Getting boundary condition frequency and 
!  fort.63 as command argument
   do k = 1, iargc()
        call  getarg(k,arg)
        if ( k.eq.1 ) then
                read (arg,'(i10)') timestep 
        else
                read (arg,'(A100)') InputFile_Elev
        endif
   end do
   write (19,'(i10)')  timestep
   open (unit=10,file=InputFile_Elev)
!  -----------------------------------------------

!  Defining formats
1  format(A100)
2  format(i10,1PE22.10E3)
3  format(1PE22.10E3)
4  format(i11,i11,A100)
!
   read (10,1) line1
   read (10,4) BLNUM, NN, line2
!  
   ttlOpenNode=sum(nvdll,DIM=1)            ! total number of open boundaries
   allocate(elevation(ttlOpenNode,1))
!
!
   jj = 1 
   do k=1,BLNUM
      read (10,1) Header
!     reading boundary node file completely to find the 1st
!     match, and allocating matching nodes to avoid repeating 
!     time-consuming step.
      do, j=1,nope
        read (10,2)  i, Elev
        do ii = 1, nvdll(j)
           write(19,3) Elev   
           ! saving for initial condition
           if (k.eq.1) then
               elevation(jj,1) = Elev ! For initial condition
               jj = jj+1
           endif
           ! ------------------------
        enddo
     enddo
!    initial condition (t=0)
     if (k.eq.1) then
        do m = 1 , ttlOpenNode
          write(19,3) elevation(m,1) 
        enddo
     endif
!    skipping additional lines that are station outouts
!    if NN (# of elevation output at each time step) is
!    bigger than nope, there are additional elevations in
!    fort.61 that indicate station outputs specified by user.
     if (NN.gt.nope) then
        do j=1,NN-nope
           read (10,2)
        enddo
     endif
   enddo
   end program bcGen      
