const PaS_FILE_LOCK_NAME = "_DATA_LOCKED"

function wait_and_lock_folder(path)
    path_to_lock = joinpath(path, PaS_FILE_LOCK_NAME)
    wait_until_unlocked(path)
    try
        open(path_to_lock, "w") do file
            # Lock is successfully created (empty file)
        end
    catch e
        error("Failed to create lock file: $path_to_lock. Error: $e")
    end
end

function remove_lock(path)
    path_to_lock = joinpath(path, PaS_FILE_LOCK_NAME)
    
    # Check and remove the lock if it exists
    if isfile(path_to_lock)
        try
            rm(path_to_lock)
        catch e
            error("Failed to remove lock file: $path_to_lock. Error: $e")
        end
    else
        error("Tried to remove a lock from an unlocked folder: $path")
    end
end

function is_folder_locked(path)
    path_to_lock = joinpath(path, PaS_FILE_LOCK_NAME)
    return isfile(path_to_lock)
end

function wait_until_unlocked(path)
    while is_folder_locked(path)
        sleep(1)  # Sleep for 1 second before checking again
    end
end