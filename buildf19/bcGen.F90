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
   INTEGER             ::  i,j,k, BLNUM, NN, NNI, BN, kk,  &
                           kkk, timestep,ll,l, NBN
   REAL                ::  Elev,M, SSAG
   real, dimension(:,:), allocatable :: elevation, node,temp
!   
   open (unit=9 ,file='Boundary_Node')
!  
!- Reading boundary node file to get the number of lines
   NBN = 1
   do i=1,999
      read (9,*,end=9998) BN
      NBN=NBN+1
   enddo 
!
9998  continue
   NBN = NBN - 1
!- Closing and opening boundary nodes since it has been read 
!  completely 
   close(9)
   open(unit=9 ,file='Boundary_Node')
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
   allocate(node(NN,1))
   allocate(temp(NBN,1))
!
!
   l=1             !to be used as initial condition index 
   do k=1,BLNUM
   read (10,1) Header
!     reading boundary node file completely to find the 1st
!     match, and allocating matching nodes to avoid repeating 
!     time-consuming step.
      do kk=1,1
         read (9,*) BN
         do, j=1,NN
            read (10,2)  i, Elev
            node(j,1) = i   
            elevation(j,1) = Elev
                if (i.eq.BN) then
                    write(19,*) Elev    
!------------------ using first time step output for IC in fort.19
                    if (k.eq.1) then 
                    temp(l,1)=Elev
                    endif
!-----------------------------------------------------------------
                end if
         enddo
!       
         do, kkk=1,999
             read (9,*,end=9999) BN
             do, j=1,NN
             if (node(j,1).eq.BN) then
                    write(19,*) elevation(j,1)
!------------------ using first time step output for IC in fort.19
                    if (k.eq.1) then
                    l=l+1
                    temp(l,1)=elevation(j,1)
                    endif
!-----------------------------------------------------------------   
             endif
             enddo
         enddo
9999 continue
!------- writing one time series of BC as intial condition by
!        copying the output of first time step form fort.63.
!        fort.19 must contain BC form t=0 to t=end.
         
!        fort.63 is written from t=0+dt to t=end.
     if (k.eq.1) then
                do ll=1,NBN
                write(19,*) temp(ll,1)
                enddo
         endif 
     enddo
!------------------------------------------------------------
     close(9)
     open(unit=9 ,file='Boundary_Node')
   enddo 
   end program pull_fort19
