const PaS_FILE_LOCK_NAME = "data_locked"

function wait_and_lock_folder(path)
    path_to_lock = joinpath(path, PaS_FILE_LOCK_NAME)
    wait_until_unlocked(path)
    open(path_to_lock, "w") do file
    end
end

function remove_lock(path)
    path_to_lock = joinpath(path, PaS_FILE_LOCK_NAME)
    if isfile(path_to_lock)
        rm(path_to_lock)
    else
        error("Tried to remove a lock from an unlocked file")
    end
end

function is_folder_locked(path)
    path_to_lock = joinpath(path, PaS_FILE_LOCK_NAME)
    return isfile(path_to_lock)
end

function wait_until_unlocked(path)
    while is_folder_locked(path)
        sleep(10)
    end
end