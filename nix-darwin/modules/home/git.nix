{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Ryan Stoffel";
      user.email = "stoffel.thomas.ryan@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
      merge.conflictstyle = "diff3";
      # HTTPS clones push over SSH through the 1Password agent; fetches stay anonymous.
      url."git@github.com:".pushInsteadOf = "https://github.com/";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      # Without these, lazygit hashes author names and branch names onto its
      # own built-in color wheel, which puts purple initials in the log.
      gui.authorColors."*" = "white";
      gui.branchColors."*" = "white";
      # lazygit 0.60+ takes a pagers array; the old git.paging object makes
      # lazygit try to rewrite its own config, which fails on a store symlink.
      git.pagers = [ { pager = "delta --paging=never"; } ];
    };
  };
}

