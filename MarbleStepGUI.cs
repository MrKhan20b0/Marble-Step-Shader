using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;

public class MarbleStepGUI : ShaderGUI
{
    static MaterialProperty FindAndRemoveProperty(string propertyName, List<MaterialProperty> propertyList)
    {
        return FindAndRemoveProperty(propertyName, propertyList, true);
    }
 
    static MaterialProperty FindAndRemoveProperty(string propertyName, List<MaterialProperty> propertyList, bool propertyIsMandatory)
    {
        for (var i = 0; i < propertyList.Count; i++)
            if (propertyList[i] != null && propertyList[i].name == propertyName)
            {
                var property = propertyList[i];
                propertyList.RemoveAt(i);
                return property;
            }
 
 
        // We assume all required properties can be found, otherwise something is broken
        if (propertyIsMandatory)
            throw new ArgumentException("Could not find MaterialProperty: '" + propertyName + "', Num properties: " + propertyList.Count);
        return null;
    }

    static void RemoveIfDisabled(string propertyName, string[] proppertiesToRemove, List<MaterialProperty> propertyList, Material targetMat) {

        if (targetMat.GetFloat(propertyName) == 0) {
            foreach (string s in proppertiesToRemove) {
                FindAndRemoveProperty(s, propertyList);
            } 
        }
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material targetMat = materialEditor.target as Material;

        List<MaterialProperty> propertyList = new List<MaterialProperty>(properties);

        // render the default gui
        // base.OnGUI(materialEditor, properties);

        UnityEngine.Debug.Log("HEY");

        RemoveIfDisabled("_ViewPitchInfluence_Toggle", new[]{"_ViewPitchInfluence"}, propertyList, targetMat);
        RemoveIfDisabled("_FilmGrain_Toggle", new[]{"_FilmGrainIntensity", "_FilmGrainColor"}, propertyList, targetMat);

        if (propertyList.Count > 0)
        {
 
            for (int i=0; i<propertyList.Count; i++)
            {
                materialEditor.ShaderProperty(propertyList[i], propertyList[i].displayName);
            }
        }
    }
}
