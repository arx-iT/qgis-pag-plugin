'''
Created on 11 dec. 2015

@author: arxit
'''
from __future__ import absolute_import

from builtins import object
import os

from qgis.core import *
from qgis.gui import *
from qgis.PyQt.QtWidgets import QFileDialog
from qgis.PyQt.QtCore import *

from ... import main
from ... import project

from .import_manager_dialog import ImportManagerDialog

class ImportManager(object):
    '''
    Main class for the import data widget
    '''

    def __init__(self):
        '''
        Constructor
        '''
        pass

    def run(self):
        '''
        Runs the widget
        '''

        if not main.current_project.isPagProject():
            return

        self.dlg = ImportManagerDialog()
        self.dlg.show()

    def rollbackImport(self, id):
        errors = False

        # Delete import from layers
        layers = [layer for layer in QgsProject.instance().mapLayers().values()]
        #for layer in main.qgis_interface.legendInterface().layers():
        for layer in layers:
            if not (layer.type() == QgsMapLayer.VectorLayer and main.current_project.isPagLayer(layer)):
                continue

            errors = errors or not self._deleteImportFromLayer(layer, id)

        # Delete entry in import log Table
        layer = main.current_project.getImportLogLayer()
        errors = errors or not self._deleteImportFromLayer(layer, id)

        if not errors:
            main.qgis_interface.messageBar().pushSuccess(QCoreApplication.translate('ImportManager', 'Success'),
                                                                       QCoreApplication.translate('ImportManager', 'Rollback was successful'))

    def _deleteImportFromLayer(self, layer, importid):
        fids = []

        expr = QgsExpression('{}=\'{}\''.format(project.IMPORT_ID, importid))
        feature_request = QgsFeatureRequest(expr)

        for feature in layer.getFeatures(feature_request):
            fids.append(feature.id())

        # Start editing session
        if not layer.isEditable():
            layer.startEditing()

        # Delete features
        layer.dataProvider().deleteFeatures(fids)

        # Commit
        if not layer.commitChanges():
            layer.rollBack()
            main.qgis_interface.messageBar().pushCritical(QCoreApplication.translate('ImportManager','Error'),
                                                                        QCoreApplication.translate('ImportManager','Commit error on layer {}').format(layer.name()))
            errors = layer.commitErrors()
            for error in errors:
                QgsMessageLog.logMessage(error, 'PAG Luxembourg', QgsMessageLog.CRITICAL)

            main.qgis_interface.openMessageLog()
            return False

        return True