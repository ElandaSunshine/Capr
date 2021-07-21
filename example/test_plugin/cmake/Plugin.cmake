# A required function for any plugin, format is plugin_init_<package>_<id>
# The target_name argument is the name of the target this plugin was applied to
# The properties argument is the map of plugin scoped properties
function(plugin_init_xyz.elandasunshine_example target_name properties)
    # Scope is global, so we have to access it with GLOBAL
    capr_plugin_get_property(out_advanced_prop GLOBAL
        PROPERTY "advanced.property"
        TARGET   ${target_name})
    
    # Scope is plugin, so the property is available in this function only we must also access it with LOCAL
    capr_plugin_get_property(out_simple_prop LOCAL
        PROPERTY "simple.property"
        TARGET   ${target_name})
    
    message("Advanced property value: ${out_advanced_prop}")
    message("Simple property value: ${out_simple_prop}")
endfunction()

# Here is anything your plugin can/needs/should do
