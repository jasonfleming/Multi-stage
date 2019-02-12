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
      program open_bn_finder
      implicit none
      integer :: ios ! i/o status
      integer :: lineNum ! line number currently being read
      integer :: neta_count, nvel_count
      integer :: nvell_max, nvdll_max
      integer, parameter :: iunit = 14
      character(len=100) :: agrid
      integer :: ne, np, mne, mnp, neta, mneta, nope,mnope, ii, jj, m
      integer, dimension(:),   allocatable  :: nvdll
      integer, dimension(:),   allocatable  :: bn_node
      real   , dimension(:,:), allocatable  :: lon_lat
      real   , dimension(:,:), allocatable  :: grid
      real    :: lon, lat,d 
      real    :: middle_node_real
      integer :: middle_node
      integer :: i
      integer :: j
      integer :: k
      integer :: c
      !
      ! for reading fort.14 and getting nope and nvdll ---------------------
      ! initializations
      lineNum = 1
      ! reading the file
      open(unit=14,file="fort_fine.14")
      read(14,fmt=*) agrid
      lineNum = lineNum + 1
      read(14,fmt=*) ne, np
      
      allocate(grid(np,1:3))
      do k = 1, np
         read(14,fmt=*) i, lon, lat, d
         grid(k,1) = i
         grid(k,2) = lon
         grid(k,3) = lat
      enddo
      do k = 1, ne
         read(14,fmt=*) i
      enddo
      !
      allocate(nvdll(np))
      read(14,fmt=*) nope  ! total number of elevation boundaries
      mnope = nope
      read(14,fmt=*) neta  ! total number of nodes on elevation boundaries
      !
      
      allocate(bn_node(nope))
      c=1   ! middle node counter
      do k = 1, nope
         read(14,fmt=*) nvdll(k) ! number of nodes on the kth elevation boundary segment
         ! We want to get the lat/lon of the node located 
         ! in the center of the open boundary nodestring
         middle_node_real=nvdll(k)/2
         middle_node=nint(middle_node_real)
         do j = 1, nvdll(k)
            read(14,fmt=*) i
            if ( j.eq.middle_node ) then
               bn_node(c) = i 
               c=c+1
            endif
         enddo
      enddo
      close(14)
      WRITE(*,*) bn_node(2)
      !
      ! Now we have the middle node at each open boundary
       
      allocate(lon_lat(nope,1:2))
      c=1
      do j = 1 , nope
      do k = 1, np
         if ( int(grid(k,1)).eq.bn_node(c) ) then
            lon_lat(c,1) = grid(k,2)
            lon_lat(c,2) = grid(k,3)
            write(*,*) lon_lat(c,1), lon_lat(c,2) 
            c=c+1
         endif
      enddo
      enddo
      !
      do k = 1, nope
         write(142,*) lon_lat(k,1), lon_lat(k,2)
      enddo
      end program open_bn_finder 
