"""AmplitudeHistogram view plugin.

This plugin adds a matplotlib view showing amplitude histograms for
the selected clusters. The percentage of undetected spikes for selected
clusters are estimated by fitting a gaussian function with a cutoff,
and displayed on the command line.

To activate the plugin, copy this file to `~/.phy/plugins/` and add this line
to your `~/.phy/phy_config.py`:

```python
c.TemplateGUI.plugins = ['AmplitudeHistogram']
```
Luke Shaheen - Laboratory of Brain, Hearing and Behavior Nov 2016
"""

import logging

import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d

from phy import IPlugin
from phy.gui.qt import AsyncCaller, busy_cursor
from phy.utils._color import _spike_colors
from pathlib import Path

logger = logging.getLogger(__name__)


class PosTrials(IPlugin):
    def attach_to_controller(self, controller):
        def _load_positionTime(self):
            return self._read_array('posTime')

        def _load_posLin1(self):
            return self._read_array('posLin1')

        def _load_trials(self):
            return self._read_array('trialsphy')

        # https://github.com/kwikteam/phy-contrib/blob/54203a01e570796edcc40a927873b5d6cbc947be/phycontrib/template/model.py
        # Create the figure when initializing the GUI.
        plt.rc('xtick', color='w')
        plt.rc('ytick', color='w')
        plt.rc('axes', edgecolor='w')
        f = plt.figure()
        ax = f.add_axes([0.15, 0.1, 0.78, 0.87])
        rect = f.patch
        rect.set_facecolor('k')
        ax.set_axis_bgcolor('k')
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.yaxis.set_ticks_position('left')
        ax.xaxis.set_ticks_position('bottom')
        ax.get_yaxis().set_tick_params(direction='out')
        ax.get_xaxis().set_tick_params(direction='out')

        time_pos = _load_positionTime(controller.model)
        posLin1 = _load_posLin1(controller.model)
        set_interp3 = interp1d(time_pos, posLin1, kind='linear', bounds_error=False, fill_value=np.nan, assume_sorted=False)
        trials1 = _load_trials(controller.model)
        set_interp4 = interp1d(time_pos, trials1, kind='nearest', bounds_error=False, fill_value=np.nan, assume_sorted=False)
        # Optogenetic position markers
        my_file = Path("optogenetics.npy")
        if my_file.is_file():
            def _load_optogenetics(self):
                return self._read_array('optogenetics')
            pos_opto = _load_optogenetics(controller.model)
            opto_x = set_interp3(pos_opto)
            opto_y = set_interp4(pos_opto)
            ax.plot(opto_x, opto_y, 'o', c='w',alpha=0.8)
        f.canvas.draw()

        def _update(clusters):
            colors = _spike_colors(np.arange(len(clusters)))
            ax.clear()
            for i in range(len(clusters)):
                new_x = set_interp3(controller._get_spike_times(clusters[i], 'None').data)
                new_y = set_interp4(controller._get_spike_times(clusters[i], 'None').data)
                ax.plot(new_x, new_y, '.', c=colors[i],alpha=0.6)
            if my_file.is_file():
                ax.plot(opto_x, opto_y, '.', c='w',alpha=0.8)
            f.canvas.draw()


        @controller.connect
        def on_gui_ready(gui):
            # Called when the GUI is created.
            # We add the matplotlib figure to the GUI.
            gui.add_view(f, name='Trials Rim')

            # Call on_select() asynchronously after a delay, and set a busy
            # cursor.
            async_caller = AsyncCaller(delay=100)

            @gui.connect_
            def on_select(cluster_ids, **kwargs):
                # Call this function after a delay unless there is another
                # cluster selection in the meantime.
                @async_caller.set
                def update_view():
                    with busy_cursor():
                        _update(cluster_ids)
