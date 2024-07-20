# observability
To create an observability platform to monitor logs, metrics and traces using eks,otel and grafana


sudo rpm --import https://releases.warp.dev/linux/keys/warp.asc
sudo sh -c 'echo -e "[warpdotdev]\nname=warpdotdev\nbaseurl=https://releases.warp.dev/linux/rpm/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://releases.warp.dev/linux/keys/warp.asc" > /etc/yum.repos.d/warpdotdev.repo'
sudo dnf install warp-terminal



eval "$(starship init bash)"

mkdir -p ~/.config && touch ~/.config/starship.toml

export STARSHIP_CONFIG=/home/ec2-user/.config