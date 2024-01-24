!                   *****************
                    SUBROUTINE DESSED
!                   *****************
!
     & (NPF,S3D_IVIDE,S3D_EPAI,S3D_HDEP,S3D_TEMP,ZR,NPOIN2,
     &  S3D_NPFMAX,S3D_NCOUCH,GRAPRD,LT,S3D_DTC,S3D_TASSE,
     &  S3D_GIBSON,NRSED,TITCAS,FMTRSED,GRADEB)
!
!***********************************************************************
! TELEMAC3D   V7P0                                   21/08/2010
!***********************************************************************
!
!brief    PROVIDES GRAPHICAL OUTPUTS
!+                FOR THE VARIABLES DESCRIBING THE MUDDY BED.
!
!warning  ONLY WORKS WITH THE S3D_GIBSONMODEL
!warning  ASSUMES THAT S3D_DTCIS IN FACT AT
!
!history  C LE NORMANT (LNH)
!+        12/06/92
!+
!+
!
!history
!+        6/05/93
!+
!+   MODIFIED
!
!history  JACEK A. JANKOWSKI PINXIT
!+        **/03/99
!+
!+   FORTRAN95 VERSION
!
!history  S.E.BOURBAN AND N.DURAND (NRC-CHC)
!+        27/03/06
!+        V5P7
!+   SELAFIN IMPLEMENTATION
!
!history  N.DURAND (HRW), S.E.BOURBAN (HRW)
!+        13/07/2010
!+        V6P0
!+   Translation of French comments within the FORTRAN sources into
!+   English comments
!
!history  N.DURAND (HRW), S.E.BOURBAN (HRW)
!+        21/08/2010
!+        V6P0
!+   Creation of DOXYGEN tags for automated documentation and
!+   cross-referencing of the FORTRAN sources
!
!history  C. VILLARET & T. BENSON & D. KELLY (HR-WALLINGFORD)
!+        27/02/2014
!+        V7P0
!+   New developments in sediment merged on 25/02/2014.
!
!history Y AUDOUIN (LNHE)
!+       25/05/2015
!+       V7P0
!+       Modification to comply with the hermes module
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| GRADEB         |-->| FIRST TIME STEP TO WRITE RESULTS
!| GRAPRD         |-->| KEYWORD 'GRAPHIC PRINTOUT PERIOD'
!| LT             |-->| CURRENT TIME STEP NUMBER
!| NDP            |-->| NUMBER OF POINTS PER ELEMENT
!| NPF            |<--| NUMBER OF POINTS WITHIN THE BED ALONG THE VERTICAL
!| NPOIN2         |-->| NUMBER OF POINTS IN 2D
!| NRSED          |-->| NUMBER OF LOGICAL UNIT OF RESULT FILE
!| S3D_BIRSED     |-->| BINARY OF FILE OF SEDIMENT TRANSPORT RESULTS
!| S3D_DTC        |-->| TIME STEP FOR CONSOLIDATION PHENOMENON
!| S3D_EPAI       |<--| THICKNESS OF SOLID FRACTION OF THE BED LAYER
!| S3D_GIBSON     |-->| S3D_GIBSONSETTLING MODEL
!| S3D_HDEP       |<--| THICKNESS OF FRESH DEPOSIT (FLUID MUD LAYER)
!| S3D_IVIDE      |<--| VOID INDEX OF MESH POINTS
!| S3D_NCOUCH     |-->| NUMBER OF LAYERS DISCRETISING THE MUD BED
!|                |   | (MULTILAYER CONSOLIDATION MODEL)
!| S3D_NPFMAX     |-->| MAXIMUM NUMBER OF HORIZONTAL PLANES DISCRETISING
!|                |   | WITHIN THE MUDDY BED (S3D_GIBSONMODEL)
!| S3D_TASSE      |-->| MULTILAYER SETTLING MODEL LOGICAL
!| S3D_TEMP       |<--| TIME COUNTER FOR CONSOLIDATION MODEL
!|                |   | (MULTILAYER MODEL)
!| TITCAS         |-->| TITLE OF TEST CASE
!| ZR             |<--| ELEVATION OF RIDIG BED
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE INTERFACE_HERMES
      USE BIEF, ONLY: NPTIR
      USE DECLARATIONS_TELEMAC3D, ONLY: MESH2D,S3D_RHOS
!
      USE DECLARATIONS_SPECIAL
      IMPLICIT NONE
!
!
      INTEGER ERR, I, IPLAN,JPLAN, IPOIN, IELEM
      INTEGER NPLAN,NPOIN3,NELEM3,NELEM2,NPTFR2,NDP,NPTFR
      CHARACTER(LEN=80) TITSEL
      DOUBLE PRECISION UNITCONV, ECOUCH,ZPLAN
!
      INTEGER, ALLOCATABLE :: IPOBO(:),IKLES(:)       ! THESE WILL BE 3D
      DOUBLE PRECISION, ALLOCATABLE :: WSEB(:), X(:), Y(:)
!
!
      INTEGER, INTENT(IN)          :: NPOIN2, S3D_NPFMAX, NRSED
      INTEGER, INTENT(IN)          :: LT,S3D_NCOUCH
      INTEGER, INTENT(IN)          :: GRAPRD, GRADEB
      INTEGER, INTENT(IN)          :: NPF(NPOIN2)
!
      DOUBLE PRECISION, INTENT(IN) :: S3D_EPAI(NPOIN2,S3D_NCOUCH)
      DOUBLE PRECISION, INTENT(IN) :: S3D_IVIDE(NPOIN2,S3D_NCOUCH+1)
      DOUBLE PRECISION, INTENT(IN) :: S3D_HDEP(NPOIN2), ZR(NPOIN2)
      DOUBLE PRECISION, INTENT(IN) ::  S3D_TEMP(S3D_NCOUCH,NPOIN2)
!
      DOUBLE PRECISION, INTENT(IN) :: S3D_DTC
      LOGICAL, INTENT(IN)          :: S3D_TASSE,S3D_GIBSON
      CHARACTER(LEN=72), INTENT(IN):: TITCAS
      CHARACTER(LEN=8), INTENT(IN) :: FMTRSED
!
      INTEGER DATE(3), TIME(3), IERR
      CHARACTER(LEN=32) :: VARNAME(4)
      INTEGER :: RECORD, NVAR
!
!----------------------------------------------------------------------
!
      IF((LT/GRAPRD)*GRAPRD.NE.LT) RETURN
!
      IF(LT.LT.GRADEB) RETURN
!
      IF(LT.EQ.0) THEN
!
        NELEM2 = MESH2D%NELEM
        NPTFR2 = MESH2D%NPTFR
!       LEC/ECR 1: NAME OF GEOMETRY FILE
        TITSEL = TITCAS // 'SERAFIN '
!
!       LEC/ECR 2: NUMBER OF 1 AND 2 DISCRETISATION FUNCTIONS
        IF(S3D_TASSE) THEN
          NVAR = 4
        ELSEIF (S3D_GIBSON) THEN
          NVAR = 4
        ELSE
          WRITE(LU,*) "UNKNOWN CONSOLIDATION OPTION"
          CALL PLANTE(1)
          STOP
        ENDIF
!
!   LEC/ECR 3: NAMES AND UNITS OF THE VARIABLES
        IF(S3D_TASSE) THEN
          VARNAME(1) = 'ELEVATION Z     M               '
          VARNAME(2) = 'EPAISSEUR VRAIE M               '
          VARNAME(3) = 'CONC. VASE      KG/M3           '
          VARNAME(4) = 'COMPTEUR TEMPS  S               '
        ELSEIF(S3D_GIBSON) THEN
          VARNAME(1) = 'ELEVATION Z     M               '
          VARNAME(2) = 'EPAISSEUR VRAIE M               '
          VARNAME(3) = 'DENSITE VRAIE   KG/M3           '
          VARNAME(4) = 'LAYER IPF                       '
        ENDIF
        CALL SET_HEADER(FMTRSED,NRSED,TITSEL,NVAR,VARNAME,IERR)
        CALL CHECK_CALL(IERR,'DESSED:SET_HEADER')
!
!   LEC/ECR 4: LIST OF 10 INTEGER PARAMETERS (AND DATE)
        IF (S3D_TASSE) THEN
          NPLAN = S3D_NCOUCH
        ELSEIF (S3D_GIBSON) THEN
          NPLAN = S3D_NPFMAX
        ENDIF
        NPTFR = NPTFR2*NPLAN    ! 3D -> TO BE CALCULATED FROM 2D
!
!   LEC/ECR 5: 4 INTEGERS
        NELEM3 = NELEM2*(NPLAN-1)    ! 3D -> TO BE CALCULATED FROM 2D
        NPOIN3 = NPOIN2*NPLAN        ! 3D -> TO BE CALCULATED FROM 2D
        NDP = 6
!
!   LEC/ECR 6: IKLE
!   BUILDS 3D LAYERED PRISMATIC MESH OUT OF 2D IMPRINT
        ALLOCATE(IKLES(NELEM3*NDP),STAT=ERR)  ! PARTICULAR CASE OF PRISMS
        CALL CHECK_ALLOCATE(ERR, 'IKLES')
        DO IPLAN = 1,NPLAN-1
          DO IELEM = 1,NELEM2
            I = ((IPLAN-1)*NELEM2+IELEM-1)*NDP
            IKLES(I+1)=MESH2D%IKLE%I(IELEM)+(IPLAN-1)*NPOIN2
            IKLES(I+2)=MESH2D%IKLE%I(IELEM+NELEM2)+(IPLAN-1)*NPOIN2
            IKLES(I+3)=MESH2D%IKLE%I(IELEM+2*NELEM2)+(IPLAN-1)*NPOIN2
            IKLES(I+4)=MESH2D%IKLE%I(IELEM)+IPLAN*NPOIN2
            IKLES(I+5)=MESH2D%IKLE%I(IELEM+NELEM2)+IPLAN*NPOIN2
            IKLES(I+6)=MESH2D%IKLE%I(IELEM+2*NELEM2)+IPLAN*NPOIN2
          ENDDO
        ENDDO
!
!
        ALLOCATE(IPOBO(NPLAN*NPOIN2),STAT=ERR)
        CALL CHECK_ALLOCATE(ERR, 'IPOBO')
        IF( NPTFR.EQ.0.AND.NPTIR.EQ.0 ) THEN
!   LEC/ECR 7: IPOBO (CASE OF FILES WITHOUT PARALLELISM)
          DO IPOIN = 1,NPLAN*NPOIN2            ! THIS IS INDEED 3D
            IPOBO(IPOIN) = 0
          ENDDO
          DO IPLAN = 1,NPLAN
            DO IPOIN = 1,NPTFR2
              IPOBO(MESH2D%NBOR%I(IPOIN)+(IPLAN-1)*NPOIN2) =
     &        IPOIN+(IPLAN-1)*NPTFR2
            ENDDO
          ENDDO
        ELSE
!   LEC/ECR 7.1: KNOLG (ONLY IN THE EVENT OF PARALLEL MODE)
          DO IPOIN = 1,NPLAN*NPOIN2            ! THIS IS INDEED 3D
            IPOBO(IPOIN) = 0
          ENDDO
          DO IPLAN = 1,NPLAN
            DO IPOIN = 1,NPOIN2
              IPOBO(IPOIN+(IPLAN-1)*NPOIN2) =
     &           MESH2D%KNOLG%I(IPOIN)+(IPLAN-1)*NPOIN2
            ENDDO
          ENDDO
        ENDIF
!
!   LEC/ECR 8 AND 9: X AND Y COORDINATES OF THE MESH NODES
!
        ALLOCATE(X(NPLAN*NPOIN2),STAT=ERR)
        CALL CHECK_ALLOCATE(ERR,'DESSED:X')
        ALLOCATE(Y(NPLAN*NPOIN2),STAT=ERR)
        CALL CHECK_ALLOCATE(ERR,'DESSED:Y')
        DO IPOIN = 1, NPOIN2
          DO IPLAN = 1,NPLAN
            X(IPOIN+(IPLAN-1)*NPOIN2) = MESH2D%X%R(IPOIN)
          ENDDO
        ENDDO
        DO IPOIN = 1, NPOIN2
          DO IPLAN = 1,NPLAN
            Y(IPOIN+(IPLAN-1)*NPOIN2) = MESH2D%Y%R(IPOIN)
          ENDDO
        ENDDO
        DATE = (/0,0,0/)
        TIME = (/0,0,0/)
        CALL SET_MESH(FMTRSED,NRSED,3,PRISM_ELT_TYPE,NDP,NPTFR,NPTIR,
     &                NELEM3,NPOIN3,IKLES,IPOBO,IPOBO,X,Y,NPLAN,
     &                DATE,TIME,0,0,IERR)
        DEALLOCATE(X)
        DEALLOCATE(Y)
        DEALLOCATE(IKLES)
        DEALLOCATE(IPOBO)
      ENDIF
!
! A TRICK TO WRITE ONE NUMBER
!
      RECORD = (LT-GRADEB/GRAPRD)
!
      IF (S3D_TASSE) THEN
!
!  /!\ THIS PART SHOULD BE ENTIRELY REVISITED ...
        UNITCONV = 1.D0                     ! VARIABLES CAN BE ENLARGED
        ALLOCATE(WSEB(S3D_NCOUCH*NPOIN2),STAT=ERR)
        CALL CHECK_ALLOCATE(ERR,'DESSED:WSEB')
! THIS IS THE Z FOR THE LAYERING -
!       DO IPOIN = 1, NPOIN2
!         WSEB(IPOIN) = ZR(IPOIN) + S3D_EPAI(IPOIN)
!       ENDDO
!       DO IPLAN = 2,S3D_NCOUCH
!         DO IPOIN = 1, NPOIN2
!           WSEB(IPOIN+NPOIN2*(IPLAN-1)) =
!                     WSEB(IPOIN+NPOIN2*(IPLAN-2))
!                     + S3D_EPAI(IPOIN+NPOIN2*(IPLAN-1))
!          ENDDO
!       ENDDO
        CALL ADD_DATA(FMTRSED,NRSED,VARNAME(1),S3D_DTC,RECORD,.TRUE.,
     &                WSEB,NPOIN3,IERR)
        CALL CHECK_CALL(IERR,'DESSED:ADD_DATA')
!
!       DO IPOIN = 1, (S3D_NCOUCH-1)*NPOIN2
!         WSEB(IPOIN) = S3D_EPAI(IPOIN+NPOIN2) * UNITCONV
!       ENDDO
!       DO IPOIN = 1, NPOIN2
!         WSEB(IPOIN+(S3D_NCOUCH-1)*NPOIN2) = S3D_HDEP(IPOIN) * UNITCONV
!       ENDDO
        CALL ADD_DATA(FMTRSED,NRSED,VARNAME(2),S3D_DTC,RECORD,.FALSE.,
     &                WSEB,NPOIN3,IERR)
        CALL CHECK_CALL(IERR,'DESSED:ADD_DATA')
!!
!       DO IPLAN = 1,S3D_NCOUCH
!         DO IPOIN = 1, NPOIN2
!           WSEB(IPOIN+NPOIN2*(IPLAN-1)) = S3D_CONC(IPLAN) * UNITCONV
!         ENDDO
!       ENDDO
        CALL ADD_DATA(FMTRSED,NRSED,VARNAME(3),S3D_DTC,RECORD,.FALSE.,
     &                WSEB,NPOIN3,IERR)
        CALL CHECK_CALL(IERR,'DESSED:ADD_DATA')
!
        CALL ADD_DATA(FMTRSED,NRSED,VARNAME(4),S3D_DTC,RECORD,.FALSE.,
     &                S3D_TEMP,NPOIN3,IERR)
        CALL CHECK_CALL(IERR,'DESSED:ADD_DATA')
        DEALLOCATE(WSEB)
!
      ELSEIF (S3D_GIBSON) THEN
!
!
! ASSUMPTIONS - Z-LEVELS:
!  * B KENUE'S BOTTOM Z-LEVEL IS ZR (1), TOP Z-LEVEL IS ZF (S3D_NPFMAX)
!  * SEDI3D'S NON-EMPTY LAYERS ARE B KENUE'S LAYERS UNDER ZF
!  * B KENUE'S PLANES FROM 1 TO S3D_NPFMAX-NPF ARE EMPTY (S3D_EPAI=0) AND
!      CORRESPOND TO SEDI3D'S PLANES FROM NPF+2 TO S3D_NPFMAX
!  * ALL EMPTY PLANES (EXCEPT FOR S3D_HDEP) ARE SET TO COINCIDENT WITH ZR
!      (ROCK BOTTOM), WHILE SEDI3D'S 1ST PLANE IS ZR
!  * B KENUE'S NON-EMPTY TOP PLANES FROM S3D_NPFMAX-NPF+1 TO S3D_NPFMAX-1
!      CORRESPOND TO SEDI3D'S PLANES FROM 2 TO NPF IN THE SAME ORDER
!  * B KENUE'S VERY TOP PLANE AT S3D_NPFMAXCORRESPONDS TO
!      SEDI3D'S NPF+1-TH PLANE, WHICH IS ALSO S3D_HDEP- EVEN IF EMPTY !
!
! ASSUMPTIONS - VARIABLE THICKNESS:
!  * B KENUE'S THICKNESS BETWEEN TWO PLANES IS STORED ON THE UPPER PLANE
!      WHICH IS CONTRARY TO SEDI3D'S CONVENTION
!  * B KENUE'S S3D_NPFMAX-TH THICKNESS STORES S3D_HDEP
!  * FOR STORAGE PURPOSES, B KENUE'S 1ST PLANE HOLDS THE NPF
!
        UNITCONV = 1.D0                     ! VARIABLES CAN BE ENLARGED
        ALLOCATE(WSEB(S3D_NPFMAX*NPOIN2),STAT=ERR)
        CALL CHECK_ALLOCATE(ERR, 'WSEB')
! TRUE LAYERING - ELEVATION Z
        DO IPOIN = 1, NPOIN2
          JPLAN = 0
          ZPLAN = ZR(IPOIN)
          DO IPLAN = 1,S3D_NPFMAX-NPF(IPOIN)
            JPLAN = JPLAN + 1
            WSEB(IPOIN+(JPLAN-1)*NPOIN2) = ZPLAN
          ENDDO
          DO IPLAN = 1,NPF(IPOIN)-1
            JPLAN = JPLAN + 1
            ECOUCH=(S3D_IVIDE(IPLAN,IPOIN)+
     &              S3D_IVIDE(IPLAN+1,IPOIN))/2.D0
            ZPLAN = ZPLAN +
     &            ( 1.D0+ECOUCH ) * S3D_EPAI(IPOIN,IPLAN)
            WSEB(IPOIN+(JPLAN-1)*NPOIN2) = ZPLAN
          ENDDO
          WSEB(IPOIN+(S3D_NPFMAX-1)*NPOIN2) = ZPLAN +
     &             S3D_HDEP(IPOIN)
        ENDDO
        CALL ADD_DATA(FMTRSED,NRSED,VARNAME(1),S3D_DTC,RECORD,.TRUE.,
     &                WSEB,NPOIN3,IERR)
        CALL CHECK_CALL(IERR,'DESSED:ADD_DATA')
! TRUE THICKNESS - THICKNESS DZ
        DO IPOIN = 1, NPOIN2
          JPLAN = 0
          DO IPLAN = 1,S3D_NPFMAX-NPF(IPOIN)
            JPLAN = JPLAN + 1
            WSEB(IPOIN+(JPLAN-1)*NPOIN2) = 0.D0
          ENDDO
          DO IPLAN = 1,NPF(IPOIN)-1
            JPLAN = JPLAN + 1
            ECOUCH=(S3D_IVIDE(IPLAN,IPOIN)+
     &              S3D_IVIDE(IPLAN+1,IPOIN))/2.D0
            WSEB(IPOIN+(JPLAN-1)*NPOIN2) =
     &          (1.D0+ECOUCH)*S3D_EPAI(IPOIN,IPLAN)*UNITCONV
          ENDDO
          WSEB(IPOIN+(S3D_NPFMAX-1)*NPOIN2) = S3D_HDEP(IPOIN) *UNITCONV
          WSEB(IPOIN) = 1.D0 * NPF(IPOIN) ! RESET THIS ONE ! OR NOT ?
        ENDDO
        CALL ADD_DATA(FMTRSED,NRSED,VARNAME(2),S3D_DTC,RECORD,.FALSE.,
     &                WSEB,NPOIN3,IERR)
        CALL CHECK_CALL(IERR,'DESSED:ADD_DATA')
! TRUE DENSITY
        DO IPOIN = 1, NPOIN2
          JPLAN = S3D_NPFMAX
          DO IPLAN = NPF(IPOIN),1,-1
            WSEB(IPOIN+(JPLAN-1)*NPOIN2) =
     &                 S3D_RHOS/(1.D0+S3D_IVIDE(IPLAN,IPOIN))
            JPLAN = JPLAN - 1
          ENDDO
          DO IPLAN = S3D_NPFMAX,NPF(IPOIN)+1,-1
            WSEB(IPOIN+(JPLAN-1)*NPOIN2) = 0.D0
            JPLAN = JPLAN - 1
          ENDDO
        ENDDO
        CALL ADD_DATA(FMTRSED,NRSED,VARNAME(3),S3D_DTC,RECORD,.FALSE.,
     &                WSEB,NPOIN3,IERR)
        CALL CHECK_CALL(IERR,'DESSED:ADD_DATA')
! LAYERING - LAYER IPF
        DO IPOIN = 1, NPOIN2
          DO IPLAN = 1,S3D_NPFMAX-1
            WSEB(IPOIN+(IPLAN-1)*NPOIN2) = IPLAN
          ENDDO
        ENDDO
        CALL ADD_DATA(FMTRSED,NRSED,VARNAME(4),S3D_DTC,RECORD,.FALSE.,
     &                WSEB,NPOIN3,IERR)
        CALL CHECK_CALL(IERR,'DESSED:ADD_DATA')
        DEALLOCATE(WSEB)
!
      ENDIF
!
!----------------------------------------------------------------------
!
      RETURN
      END