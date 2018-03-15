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
   program pull_fort19 
   IMPLICIT none
!   
   CHARACTER(LEN=100)  ::  line1,line2,Header,InputFile_Elev, arg
   INTEGER             ::  i,j,k, BLNUM, NN, timestep
   REAL                ::  Elev
   real, dimension(:,:), allocatable :: elevation
!   
!  -----------------------------------------------
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
   allocate(elevation(NN,1))
!
!
   do k=1,BLNUM
      read (10,1) Header
!     reading boundary node file completely to find the 1st
!     match, and allocating matching nodes to avoid repeating 
!     time-consuming step.
      do, j=1,NN
        read (10,2)  i, Elev
        elevation(j,1) = Elev
        write(19,3) Elev    
     enddo
!    initial condition (t=0)
     if (k.eq.1) then
         do, j=1,NN
           write(19,3) elevation(j,1)
         enddo
     endif
   enddo
   end program pull_fort19
