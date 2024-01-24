
"""
Validation script for break
"""
from vvytel.vnv_study import AbstractVnvStudy
from execution.telemac_cas import TelemacCas, get_dico

class VnvStudy(AbstractVnvStudy):
    """
    Class for validation
    """

    def _init(self):
        """
        Defines the general parameter
        """
        self.rank = 4
        self.tags = ['telemac2d']

    def _pre(self):
        """
        Defining the studies
        """

        # break scalar mode
        self.add_study('vnv_1',
                       'telemac2d',
                       't2d_break.cas')


        # break parallel mode
        cas = TelemacCas('t2d_break.cas', get_dico('telemac2d'))
        cas.set('PARALLEL PROCESSORS', 4)

        self.add_study('vnv_2',
                       'telemac2d',
                       't2d_break_par.cas',
                       cas=cas)

        del cas



    def _check_results(self):
        """
        Post-treatment processes
        """

        # Comparison with the last time frame of the reference file.
        self.check_epsilons('vnv_1:T2DRES',
                            'f2d_break.slf',
                            eps=[0.003, 0.002, 0.0002, 0.002])

        # Comparison with the last time frame of the reference file.
        self.check_epsilons('vnv_2:T2DRES',
                            'f2d_break.slf',
                            eps=[0.003, 0.002, 0.0003, 0.002])

        # Comparison between sequential and parallel run.
        self.check_epsilons('vnv_1:T2DRES',
                            'vnv_2:T2DRES',
                            eps=[0.003, 0.002, 0.0004, 0.0007])


    def _post(self):
        """
        Post-treatment processes
        """

        from postel.plot_vnv import vnv_plot2d
        # Getting files
        res_vnv_1_t2dres, _ = self.get_study_res('vnv_1:T2DRES')
        res_vnv_1_t2dgeo, _ = self.get_study_res('vnv_1:T2DGEO', load_bnd=True)

        #Plotting mesh
        vnv_plot2d('',
                   res_vnv_1_t2dgeo,
#                   plot_mesh=True,
                   annotate_bnd=True,
                   fig_size=(15, 10),
                   fig_name='img/BC')

        # Plotting FREE SURFACE at final time step
        vnv_plot2d('FREE SURFACE',
                   res_vnv_1_t2dres,
                   record=-1,
                   cbar_label='Free surface (m)',
                   filled_contours=True,
                   fig_size=(15, 8.5),
                   fig_name='img/FreeSurface')

        # Plotting VELOCITY at final time step
        vnv_plot2d('VELOCITY',
                   res_vnv_1_t2dres,
                   record=-1,
                   filled_contours=True,
                   fig_size=(15, 8.5),
                   fig_name='img/Velocity',
                   cbar_label='Velocity (m/s)')
#                   vect_name='VELOCITY',
#                   vectors=True,
#                   vectors_scale=25)

        # Closing files
        res_vnv_1_t2dres.close()
        res_vnv_1_t2dgeo.close()