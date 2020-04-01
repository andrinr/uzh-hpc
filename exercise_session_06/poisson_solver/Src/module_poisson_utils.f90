!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! -*- Mode: F90 -*- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! module_poisson_utils.f90 --- 
!!!!
!! function boundary
!! function source_term
!! function exact_solution
!! function mat_norm2
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

module poisson_utils

contains

subroutine halo
    use poisson_mpi
    use poisson_commons
    use poisson_const
    use poisson_parameters

    implicit none

    ! Local variables
    integer, dimension(8) :: requests = (/0,0,0,0,0,0,0,0/)
    integer :: code
    real(kind=prec_real) :: snd_buf_left(ny), rcv_buf_left(ny)
    real(kind=prec_real) :: snd_buf_right(ny), rcv_buf_right(ny)
    real(kind=prec_real) :: snd_buf_down(ny), rcv_buf_down(ny)
    real(kind=prec_real) :: snd_buf_up(ny), rcv_buf_up(ny)
    integer, dimension(MPI_STATUS_SIZE,8) :: status

    do i = 1, 8, +1
        requests(i) = MPI_REQUEST_NULL
    end do

    ! Send/Receive data from left
    ! Store the reveiced array in "uold"
    if (boundary_left .eqv. .true.) then
        print*,'subroutine halo: Need to communicate with left neighbor'
        call MPI_IRECV(uold(imin, jmin : jmax), jmax - jmin, MPI_INTEGER, myleft, 1, COMM_CART, requests(1), code)
        call MPI_ISEND(uold(imin+1, jmin : jmax), jmax - jmin, MPI_INTEGER, myleft, 1, COMM_CART, requests(2), code)
    end if
    ! Send/Receive data from right
    if (boundary_right .eqv. .true.) then
        print*,'subroutine halo: Need to communicate with right neighbor'
        call MPI_IRECV(uold(imax, jmin : jmax), jmax - jmin, MPI_INTEGER, myright, 1, COMM_CART, requests(3), code)
        call MPI_ISEND(uold(imax-1, jmin : jmax), jmax - jmin, MPI_INTEGER, myright, 1, COMM_CART, requests(4), code)
    end if

    if (boundary_down .eqv. .true.) then
        print*,'subroutine halo: Need to communicate with down neighbor'
        call MPI_IRECV(uold(imin : imax, jmin), imax - imin, MPI_INTEGER, mydown, 1, COMM_CART, requests(5), code)
        call MPI_ISEND(uold(imin : imax, jmin+1), imax - imin, MPI_INTEGER, mydown, 1, COMM_CART, requests(6), code)
    end if

    if (boundary_up .eqv. .true.) then
        print*,'subroutine halo: Need to communicate with up neighbor'
        call MPI_IRECV(uold(imin : imax, jmax), imax - imin, MPI_INTEGER, myup, 1, COMM_CART, requests(7), code)
        call MPI_ISEND(uold(imin : imax, jmax-1), imax - imin, MPI_INTEGER, myup, 1, COMM_CART, requests(8), code)
    end if

    print*,'reached'
    call MPI_WAITALL(8,requests, status)

    call MPI_BARRIER(MPI_COMM_WORLD,ierror)
    return 

end subroutine halo

function boundary (x,y)
    use poisson_parameters
    use poisson_const
    implicit none

    ! Dummy arguments
    real(kind=prec_real) boundary
    real(kind=prec_real), intent(in)  :: x
    real(kind=prec_real), intent(in)  :: y

    ! Dirichlet boundary conditions
    boundary = 0

    return

end function boundary

function source_term ( x, y )
    use poisson_parameters
    use poisson_const

    implicit none

    real(kind=prec_real) source_term
    real(kind=prec_real), intent(in)  :: x
    real(kind=prec_real), intent(in)  :: y

    ! source terms 
    source_term = 8*pi*pi * sin( 2.0*pi*x) * sin( 2.0*pi*y)

    return

end function source_term

function exact_solution ( x, y )
    use poisson_parameters
    use poisson_const
    implicit none

    real(kind=prec_real) exact_solution
    real(kind=prec_real), intent(in)  :: x
    real(kind=prec_real), intent(in)  :: y

    ! exact solutions to Poisson eq. with source terms 
    exact_solution = - sin(2.0*pi * x) * sin(2.0*pi * y)
  return
end function exact_solution

function mat_norm2 (mat)
    use poisson_commons
    use poisson_parameters
    use poisson_mpi

    implicit none
    
    real(kind=prec_real) mat(myn,ny)
    real(kind=prec_real) mat_norm2

    mat_norm2 =  sum ( mat(:,:)**2 )
    return
end function mat_norm2

end module poisson_utils
