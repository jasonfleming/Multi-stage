        program edit22nhc
        implicit none
        integer :: k, t, io
        character(len=29)  :: seg1
        character(len=274) :: seg2, arg
        real :: spinUp
        !
        !  -----------------------------------------------
        !  Getting stage two spin-up (if <0)
        do k = 1, iargc()
        call  getarg(k,arg)
        if ( k.eq.1 ) then
                read (arg,*) spinUp
        endif
        end do
        ! ------------------------------------------------
11      format(a29,i4,a275)
        open(unit=23,file="fort.22.shorter")
        !          
        io = 0.0
        spinUp=spinUp*24        ! Converting spin-up day to hours
        do
        if (io.eq.0.0) then
          read(23,11,iostat=io) seg1,t,seg2   ! reading from fort.22
          t = t+spinUp     ! Spin-up is negative
          if (io.eq.0.0) then
              write(22,'(a29,i4,",",a274)')seg1,t,seg2  
          end if
        else
            go to 20
        endif
        enddo
!-------------------------------------------------
        20  continue
        end program edit22nhc
